require 'active_record'
require 'active_record/connection_adapters/abstract_adapter'

module ActiveRecord
  module ConnectionAdapters
    class JsonRecordAdapter < AbstractAdapter
      ADAPTER_NAME = 'JsonRecord'.freeze
      
      class << self
        def new_client(config)
          # Extract JsonRecord-specific configuration
          {
            database_path: config[:database],
            vector_engine: config[:vector_engine]&.to_sym || :simple,
            enable_compression: config[:enable_compression] != false,
            rocksdb_options: config[:rocksdb_options] || {}
          }
        end
      end
      
      def initialize(connection, logger, connection_parameters, config)
        super(connection, logger, connection_parameters, config)
        
        # Configure JsonRecord with database.yml settings
        configure_jsonrecord(config)
        
        # Initialize storage adapters (the plumbing infrastructure)
        @document_storage = create_document_storage
        @vector_storage = create_vector_storage
        
        @schema_cache = SchemaCache.new(self)
      end
      
      # Connection management (German engineering precision)
      def active?
        @document_storage&.connected? || true  # JsonRecord is always "connected"
      end
      
      def reconnect!
        disconnect!
        @document_storage = create_document_storage
        @vector_storage = create_vector_storage
      end
      
      def disconnect!
        @document_storage&.close if @document_storage.respond_to?(:close)
        @document_storage = nil
        @vector_storage = nil
      end
      
      def reset!
        reconnect!
      end
      
      # Database operations (Soviet-style direct access)
      def execute(sql, name = nil)
        # For now, JsonRecord doesn't support raw SQL
        # This would need SQL-to-JsonRecord query translation
        raise NotImplementedError, "Raw SQL not supported in JsonRecord adapter. Use ActiveRecord query interface."
      end
      
      # Schema operations (table plumbing)
      def tables
        @document_storage.list_tables
      end
      
      def table_exists?(table_name)
        @document_storage.table_exists?(table_name.to_s)
      end
      
      def create_table(table_name, **options)
        @document_storage.create_table(table_name.to_s, options)
        
        # Store table schema information
        schema_cache.clear_data_source_cache!(table_name.to_s)
      end
      
      def drop_table(table_name, **options)
        @document_storage.drop_table(table_name.to_s)
        schema_cache.clear_data_source_cache!(table_name.to_s)
      end
      
      def add_column(table_name, column_name, type, **options)
        @document_storage.add_column(table_name.to_s, column_name.to_s, type, options)
        schema_cache.clear_data_source_cache!(table_name.to_s)
      end
      
      def remove_column(table_name, column_name, type = nil, **options)
        @document_storage.remove_column(table_name.to_s, column_name.to_s)
        schema_cache.clear_data_source_cache!(table_name.to_s)
      end
      
      # Column information (pipe specifications)
      def columns(table_name)
        column_definitions = @document_storage.table_schema(table_name.to_s) || []
        
        column_definitions.map do |column_def|
          Column.new(
            column_def[:name],
            column_def[:default],
            column_def[:sql_type_metadata],
            column_def[:null],
            column_def[:collation]
          )
        end
      end
      
      # Primary key detection
      def primary_key(table_name)
        'id'  # JsonRecord uses 'id' as primary key by convention
      end
      
      # CRUD operations (the core plumbing functions)
      def select_all(arel, name = nil, binds = [], preparable: nil)
        # Convert ActiveRecord query to JsonRecord operations
        sql = to_sql(arel, binds)
        query_result = execute_jsonrecord_query(arel)
        
        ActiveRecord::Result.new(query_result[:columns], query_result[:rows])
      end
      
      def insert(arel, name = nil, pk = nil, id_value = nil, sequence_name = nil, binds = [])
        table_name = arel.ast.relation.name
        
        # Extract values from INSERT statement
        attributes = extract_insert_attributes(arel)
        
        # Generate ID if not provided
        id_value ||= next_sequence_value(table_name)
        attributes['id'] = id_value
        
        # Store document
        @document_storage.put_document(table_name, id_value, attributes)
        
        # Handle vector fields
        handle_vector_fields(table_name, id_value, attributes)
        
        id_value
      end
      
      def update(arel, name = nil, binds = [])
        table_name = arel.ast.relation.name
        
        # Extract UPDATE conditions and values
        conditions = extract_where_conditions(arel)
        updates = extract_update_values(arel)
        
        # Find matching documents
        matching_docs = find_documents_by_conditions(table_name, conditions)
        
        # Update each document
        updated_count = 0
        matching_docs.each do |doc|
          merged_doc = doc.merge(updates)
          @document_storage.put_document(table_name, doc['id'], merged_doc)
          handle_vector_fields(table_name, doc['id'], merged_doc)
          updated_count += 1
        end
        
        updated_count
      end
      
      def delete(arel, name = nil, binds = [])
        table_name = arel.ast.relation.name
        conditions = extract_where_conditions(arel)
        
        # Find and delete matching documents
        matching_docs = find_documents_by_conditions(table_name, conditions)
        
        deleted_count = 0
        matching_docs.each do |doc|
          @document_storage.delete_document(table_name, doc['id'])
          # Remove from vector storage too
          remove_vector_fields(table_name, doc['id'])
          deleted_count += 1
        end
        
        deleted_count
      end
      
      # JsonRecord-specific extensions (vector similarity sensors)
      def similar_to(table_name, vector, options = {})
        # This would be called by ActiveRecord models for vector similarity
        collection_name = "#{table_name}_#{options[:field] || auto_detect_vector_field(table_name)}"
        
        @vector_storage.search_similar(collection_name, vector, options)
      end
      
      # Vector field management (smart sensor installation)
      def add_vector_field(table_name, field_name, dimensions)
        # Store vector field metadata
        vector_fields = @document_storage.get_metadata(table_name, 'vector_fields') || {}
        vector_fields[field_name.to_s] = { dimensions: dimensions }
        @document_storage.set_metadata(table_name, 'vector_fields', vector_fields)
        
        # Update JsonRecord configuration
        collection_name = "#{table_name}_#{field_name}"
        JSONRecord.configuration.vector_dimensions[collection_name] = dimensions
      end
      
      private
      
      def configure_jsonrecord(config)
        # Apply database.yml configuration to JsonRecord
        JSONRecord.configure do |jsonrecord_config|
          jsonrecord_config.database_path = config[:database] if config[:database]
          jsonrecord_config.vector_engine = config[:vector_engine].to_sym if config[:vector_engine]
          jsonrecord_config.enable_compression = config[:enable_compression] if config.key?(:enable_compression)
          jsonrecord_config.rocksdb_options.merge!(config[:rocksdb_options]) if config[:rocksdb_options]
        end
      end
      
      def create_document_storage
        # Use existing JsonRecord storage infrastructure
        begin
          require 'rocksdb'
          JSONRecord::Storage::RocksDBAdapter.new
        rescue LoadError, RuntimeError => e
          puts "🔧 RocksDB not available, using FileAdapter fallback: #{e.message}"
          JSONRecord::Storage::FileAdapter.new
        end
      end
      
      def create_vector_storage
        JSONRecord::Storage::VectorAdapter.new
      end
      
      def execute_jsonrecord_query(arel)
        # This is where we'd convert ActiveRecord queries to JsonRecord operations
        # For now, return empty result
        {
          columns: ['id'],
          rows: []
        }
      end
      
      def extract_insert_attributes(arel)
        # Extract attribute values from INSERT AST
        # This would parse the Arel AST to get column values
        {}
      end
      
      def extract_where_conditions(arel)
        # Extract WHERE conditions from AST
        # Convert to JsonRecord query format
        {}
      end
      
      def extract_update_values(arel)
        # Extract SET values from UPDATE AST
        {}
      end
      
      def find_documents_by_conditions(table_name, conditions)
        # Use JsonRecord query system to find matching documents
        @document_storage.find_documents(table_name, conditions)
      end
      
      def handle_vector_fields(table_name, document_id, attributes)
        # Check for vector fields and update vector storage
        vector_fields = @document_storage.get_metadata(table_name, 'vector_fields') || {}
        
        vector_fields.each do |field_name, config|
          if attributes.key?(field_name) && attributes[field_name]
            collection_name = "#{table_name}_#{field_name}"
            @vector_storage.add_vector(collection_name, document_id, attributes[field_name])
          end
        end
      end
      
      def remove_vector_fields(table_name, document_id)
        # Remove from all vector collections for this table
        vector_fields = @document_storage.get_metadata(table_name, 'vector_fields') || {}
        
        vector_fields.each do |field_name, config|
          collection_name = "#{table_name}_#{field_name}"
          @vector_storage.remove_vector(collection_name, document_id)
        end
      end
      
      def next_sequence_value(table_name)
        # Generate next ID for table (simple auto-increment)
        @document_storage.next_id(table_name)
      end
      
      def auto_detect_vector_field(table_name)
        vector_fields = @document_storage.get_metadata(table_name, 'vector_fields') || {}
        
        if vector_fields.size == 1
          vector_fields.keys.first
        else
          raise ArgumentError, "Multiple vector fields found. Please specify field: parameter"
        end
      end
    end
  end
end

# Register adapter with ActiveRecord
ActiveRecord::ConnectionAdapters.register("jsonrecord", "ActiveRecord::ConnectionAdapters::JsonRecordAdapter", "active_record/connection_adapters/jsonrecord_adapter")
