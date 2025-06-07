require 'json'     # Use JSON for consistency with RocksDB
require 'fileutils'

module JSONRecord
  module Storage
    class FileAdapter
      attr_reader :data_dir, :indexes
      
      def initialize(data_dir = nil)
        @data_dir = data_dir || default_data_dir
        @indexes = {}
        ensure_data_directory
      end
      
      # Document operations (improved file-based storage)
      def put_document(table_name, id, document)
        table_dir = table_directory(table_name)
        FileUtils.mkdir_p(table_dir)
        
        file_path = document_file_path(table_name, id)
        json_data = JSON.generate(document)  # Use JSON instead of MessagePack
        
        # Atomic write (German precision)
        temp_file = "#{file_path}.tmp"
        File.write(temp_file, json_data)
        File.rename(temp_file, file_path)
        
        # Update indexes
        update_indexes(table_name, id, document)
        
        document
      end
      
      def get_document(table_name, id)
        file_path = document_file_path(table_name, id)
        return nil unless File.exist?(file_path)
        
        json_data = File.read(file_path)
        JSON.parse(json_data)  # Parse JSON instead of MessagePack
      rescue => e
        puts "Error reading document #{table_name}:#{id}: #{e.message}"
        nil
      end
      
      def delete_document(table_name, id)
        document = get_document(table_name, id)
        return nil unless document
        
        file_path = document_file_path(table_name, id)
        File.delete(file_path) if File.exist?(file_path)
        
        # Clean up indexes
        cleanup_indexes(table_name, id, document)
        
        document
      end
      
      def find_documents(table_name, conditions = {})
        table_dir = table_directory(table_name)
        return [] unless Dir.exist?(table_dir)
        
        if conditions.empty?
          # Return all documents
          all_documents(table_name)
        else
          # Use indexes for filtering
          find_by_conditions(table_name, conditions)
        end
      end
      
      # Index operations (like card catalog system)
      def create_index(table_name, field_name, value, document_id)
        index_dir = index_directory(table_name, field_name)
        FileUtils.mkdir_p(index_dir)
        
        index_file = index_file_path(table_name, field_name, value)
        existing_ids = get_index_ids(index_file)
        existing_ids << document_id.to_s unless existing_ids.include?(document_id.to_s)
        
        File.write(index_file, JSON.generate(existing_ids))  # Use JSON
      end
      
      def remove_from_index(table_name, field_name, value, document_id)
        index_file = index_file_path(table_name, field_name, value)
        return unless File.exist?(index_file)
        
        existing_ids = get_index_ids(index_file)
        existing_ids.delete(document_id.to_s)
        
        if existing_ids.empty?
          File.delete(index_file)
        else
          File.write(index_file, JSON.generate(existing_ids))  # Use JSON
        end
      end
      
      def find_by_index(table_name, field_name, value)
        index_file = index_file_path(table_name, field_name, value)
        return [] unless File.exist?(index_file)
        
        document_ids = get_index_ids(index_file)
        document_ids.map { |id| get_document(table_name, id) }.compact
      end
      
      # Database management
      def database_size
        total_files = 0
        Dir.glob(File.join(@data_dir, "**", "*.json")).each { total_files += 1 }  # Count JSON files
        total_files
      end
      
      def compact!
        # For file-based storage, we don't need compaction
        puts "File-based storage doesn't require compaction"
      end
      
      private
      
      def default_data_dir
        if defined?(Rails)
          Rails.root.join('db', 'jsonrecord_data')
        else
          File.join(Dir.pwd, 'data', 'jsonrecord')
        end
      end
      
      def ensure_data_directory
        FileUtils.mkdir_p(@data_dir) unless Dir.exist?(@data_dir)
      end
      
      def table_directory(table_name)
        File.join(@data_dir, table_name.to_s)
      end
      
      def document_file_path(table_name, id)
        File.join(table_directory(table_name), "#{id}.json")  # Use .json extension
      end
      
      def index_directory(table_name, field_name)
        File.join(@data_dir, 'indexes', table_name.to_s, field_name.to_s)
      end
      
      def index_file_path(table_name, field_name, value)
        # Sanitize value for filename
        safe_value = value.to_s.gsub(/[^a-zA-Z0-9._-]/, '_')
        File.join(index_directory(table_name, field_name), "#{safe_value}.idx")
      end
      
      def get_index_ids(index_file)
        return [] unless File.exist?(index_file)
        
        json_data = File.read(index_file)
        JSON.parse(json_data)  # Parse JSON instead of MessagePack
      rescue
        []
      end
      
      def all_documents(table_name)
        table_dir = table_directory(table_name)
        return [] unless Dir.exist?(table_dir)
        
        documents = []
        Dir.glob(File.join(table_dir, "*.json")).each do |file_path|
          begin
            json_data = File.read(file_path)
            document = JSON.parse(json_data)  # Parse JSON
            documents << document
          rescue => e
            puts "Error reading #{file_path}: #{e.message}"
          end
        end
        
        documents
      end
      
      def find_by_conditions(table_name, conditions)
        # Start with first condition and filter
        first_condition = conditions.first
        field_name, value = first_condition
        
        candidates = case value
                    when Hash
                      handle_complex_condition(table_name, field_name, value)
                    else
                      find_by_index(table_name, field_name, value)
                    end
        
        # Filter candidates by remaining conditions
        remaining_conditions = conditions[1..-1] || []
        candidates.select { |doc| matches_conditions?(doc, remaining_conditions) }
      end
      
      def handle_complex_condition(table_name, field_name, condition_hash)
        results = []
        
        condition_hash.each do |operator, value|
          case operator.to_sym
          when :includes
            results.concat(find_by_index(table_name, "#{field_name}_includes", value))
          when :gte, :gt, :lte, :lt
            # For range queries, we need to scan all documents (less efficient)
            all_docs = all_documents(table_name)
            filtered = all_docs.select do |doc|
              field_value = get_nested_field(doc, field_name)
              compare_values(field_value, operator, value)
            end
            results.concat(filtered)
          end
        end
        
        results.uniq
      end
      
      def update_indexes(table_name, id, document)
        document.each do |field_name, value|
          case value
          when String, Numeric, TrueClass, FalseClass
            create_index(table_name, field_name, value, id)
          when Array
            value.each do |item|
              create_index(table_name, "#{field_name}_includes", item, id)
            end
          end
        end
      end
      
      def cleanup_indexes(table_name, id, document)
        document.each do |field_name, value|
          case value
          when String, Numeric, TrueClass, FalseClass
            remove_from_index(table_name, field_name, value, id)
          when Array
            value.each do |item|
              remove_from_index(table_name, "#{field_name}_includes", item, id)
            end
          end
        end
      end
      
      def matches_conditions?(document, conditions)
        conditions.all? do |field_name, expected_value|
          actual_value = get_nested_field(document, field_name)
          
          case expected_value
          when Hash
            expected_value.all? do |operator, value|
              compare_values(actual_value, operator, value)
            end
          else
            actual_value == expected_value
          end
        end
      end
      
      def get_nested_field(document, field_path)
        keys = field_path.to_s.split('.')
        keys.reduce(document) { |obj, key| obj.is_a?(Hash) ? obj[key] : nil }
      end
      
      def compare_values(actual, operator, expected)
        return false if actual.nil?
        
        case operator.to_sym
        when :gte then actual >= expected
        when :gt  then actual > expected
        when :lte then actual <= expected
        when :lt  then actual < expected
        when :includes then actual.respond_to?(:include?) && actual.include?(expected)
        else false
        end
      end
    end
  end
end
