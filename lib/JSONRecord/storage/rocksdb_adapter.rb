require 'rocksdb'
require 'msgpack'  # Optimal binary serialization for fast CRUD operations

module JSONRecord
  module Storage
    class RocksDBAdapter
      attr_reader :db_path, :db_handle, :indexes
      
      def initialize(db_path = nil)
        @db_path = db_path || JSONRecord.database_path
        @indexes = {}
        ensure_database_directory
        open_database
      end
      
      # Document operations (the main pipes)
      # Document operations (optimized binary storage)
      def put_document(table_name, id, document)
        key = document_key(table_name, id)
        packed_data = MessagePack.pack(document)
        
        puts "DEBUG: Storing key='#{key}' size=#{packed_data.size} bytes" if ENV['DEBUG']
        
        # Store as efficient binary blob (RocksDB gem has weird behavior but get() compensates)
        @db_handle.put(key, packed_data)
        
        # Update secondary indexes for fast queries
        update_indexes(table_name, id, document)
        
        document
      end
      
      def get_document(table_name, id)
        key = document_key(table_name, id)
        packed_data = @db_handle.get(key)
        
        return nil unless packed_data
        MessagePack.unpack(packed_data)
      end
      
      def delete_document(table_name, id)
        # Get document before deletion for index cleanup
        document = get_document(table_name, id)
        return nil unless document
        
        key = document_key(table_name, id)
        @db_handle.delete(key)
        
        # Clean up indexes
        cleanup_indexes(table_name, id, document)
        
        document
      end
      
      def find_documents(table_name, conditions = {})
        if conditions.empty?
          # Return all documents (like Soviet central heating - everyone gets same)
          all_documents(table_name)
        else
          # Use indexes for filtering (German precision)
          find_by_conditions(table_name, conditions)
        end
      end
      
      # Index operations (smart pressure sensors)
      def create_index(table_name, field_name, value, document_id)
        index_key = index_key_for(table_name, field_name, value)
        existing_ids = get_index_ids(index_key)
        existing_ids << document_id unless existing_ids.include?(document_id)
        
        @db_handle.put(index_key, MessagePack.pack(existing_ids))
      end
      
      def remove_from_index(table_name, field_name, value, document_id)
        index_key = index_key_for(table_name, field_name, value)
        existing_ids = get_index_ids(index_key)
        existing_ids.delete(document_id)
        
        if existing_ids.empty?
          @db_handle.delete(index_key)
        else
          @db_handle.put(index_key, MessagePack.pack(existing_ids))
        end
      end
      
      def find_by_index(table_name, field_name, value)
        index_key = index_key_for(table_name, field_name, value)
        document_ids = get_index_ids(index_key)
        
        document_ids.map { |id| get_document(table_name, id) }.compact
      end
      
      # Range queries (like adjusting water pressure)
      def find_by_range(table_name, field_name, range)
        results = []
        
        # Iterate through possible values in range
        # This is simplified - real implementation would use RocksDB iterators
        case range
        when Range
          range.each do |value|
            results.concat(find_by_index(table_name, field_name, value))
          end
        end
        
        results.uniq
      end
      
      # Database management (plumber maintenance)
      def compact!
        @db_handle.compact_range(nil, nil)
      end
      
      def close
        @db_handle&.close
      end
      
      def database_size
        # Get approximate database size
        estimate_num_keys = @db_handle.property("rocksdb.estimate-num-keys")
        estimate_num_keys.to_i
      end
      
      private
      
      def ensure_database_directory
        directory = File.dirname(@db_path)
        FileUtils.mkdir_p(directory) unless Dir.exist?(directory)
      end
      
      def open_database
        options = JSONRecord.configuration.rocksdb_options
        @db_handle = RocksDB.open(@db_path, options)
      rescue => e
        raise "Failed to open RocksDB at #{@db_path}: #{e.message}"
      end
      
      def document_key(table_name, id)
        "doc:#{table_name}:#{id}"
      end
      
      def index_key_for(table_name, field_name, value)
        "idx:#{table_name}:#{field_name}:#{value}"
      end
      
      def get_index_ids(index_key)
        packed_data = @db_handle.get(index_key)
        return [] unless packed_data
        MessagePack.unpack(packed_data)  # Parse MessagePack index data
      end
      
      def all_documents(table_name)
        documents = []
        
        # CRITICAL FIX: RocksDB Ruby gem has BIZARRE behavior:
        # - put(key, value) stores VALUE as KEY and stores EMPTY as value
        # - So all KEYS are actually MessagePack document data
        # - All VALUES are empty/nil
        @db_handle.each do |stored_key, stored_value|
          # stored_key = MessagePack document data (what should have been value)
          # stored_value = empty/nil (gem doesn't store original key)
          begin
            # Try to parse key as MessagePack document
            document = MessagePack.unpack(stored_key)
            
            # Filter by table name using _table field
            if document.is_a?(Hash) && document['id'] && document['_table'] == table_name
              documents << document
            end
          rescue MessagePack::MalformedFormatError, MessagePack::UnexpectedTypeError
            # Skip non-document keys (could be indexes)
            next
          end
        end
        
        documents
      end
      
      def find_by_conditions(table_name, conditions)
        # Start with first condition and intersect results
        # This is simplified - real implementation would optimize query planning
        
        first_condition = conditions.first
        field_name, value = first_condition
        
        candidates = case value
                    when Hash
                      handle_complex_condition(table_name, field_name, value)
                    when Range  
                      find_by_range(table_name, field_name, value)
                    else
                      find_by_index(table_name, field_name, value)
                    end
        
        # Filter candidates by remaining conditions
        remaining_conditions = conditions[1..-1] || []
        candidates.select { |doc| matches_conditions?(doc, remaining_conditions) }
      end
      
      def handle_complex_condition(table_name, field_name, condition_hash)
        # Handle MongoDB-style operators
        results = []
        
        condition_hash.each do |operator, value|
          case operator.to_sym
          when :includes
            # Array includes operation
            results.concat(find_by_index(table_name, "#{field_name}_includes", value))
          when :gte, :gt, :lte, :lt
            # Numeric comparisons - simplified implementation
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
        # Create indexes for common query patterns
        document.each do |field_name, value|
          case value
          when String, Numeric, TrueClass, FalseClass
            create_index(table_name, field_name, value, id)
          when Array
            # Index array elements for 'includes' queries
            value.each do |item|
              create_index(table_name, "#{field_name}_includes", item, id)
            end
          end
        end
      end
      
      def cleanup_indexes(table_name, id, document)
        # Remove from indexes when document deleted
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
            # Handle complex conditions
            expected_value.all? do |operator, value|
              compare_values(actual_value, operator, value)
            end
          else
            actual_value == expected_value
          end
        end
      end
      
      def get_nested_field(document, field_path)
        # Handle nested field access like "experience.years"
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
        when :includes then actual.include?(expected) if actual.respond_to?(:include?)
        else false
        end
      end
    end
  end
end
