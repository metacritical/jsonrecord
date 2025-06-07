module JSONRecord
  # Storage adapters (the plumbing infrastructure)
  def document_storage
    # Use class-level singleton to avoid multiple RocksDB connections
    @@document_storage ||= begin
      # Try RocksDB first (German precision), fallback to FileAdapter (Soviet reliability)
      begin
        require 'rocksdb'
        JSONRecord::Storage::RocksDBAdapter.new
      rescue LoadError, RuntimeError => e
        puts "🔧 RocksDB not available, using FileAdapter fallback: #{e.message}"
        JSONRecord::Storage::FileAdapter.new
      end
    end
  end
  
  def vector_storage  
    @vector_storage ||= JSONRecord::Storage::VectorAdapter.new
  end
  
  # Inspection and metadata (German engineering diagnostics)
  def inspect
    if document_storage
      self.is_a?(Class) ? "#{self.to_s}(#{columns})" : "#{self.to_s}"
    else
      self.parent_name.eql?("JSONRecord") ? self.to_s : "#{self.to_s}(Storage not initialized!)"
    end
  end
  
  def table_name
    if self.is_a? Class
      # Simplified check - avoid complex ancestor checks that trigger method_missing
      return self.to_s.pluralize.downcase unless self.name == 'JSONRecord'
      raise AttributeError, "Cannot use JSONRecord directly as a model"
    else
      self.class.to_s.pluralize.downcase
    end
  end

  def scoped
    QueryBuilder.new(self)
  end
  
  # Scoped and unscoped alias method for active record compatibility
  alias_method :unscoped, :scoped

  def connection
    document_storage
  end
  
  # Core querying methods (ActiveRecord compatibility)
  def find(id)
    document = document_storage.get_document(table_name, id.to_i)
    
    if document.nil? || document.empty?
      raise RecordNotFound, "Record Not Found for #{self} with id=#{id}"
    else
      new(document)
    end
  end
  
  def where(conditions = {})
    QueryBuilder.new(self).where(conditions)
  end
  
  def similar_to(vector, options = {})
    QueryBuilder.new(self).similar_to(vector, options)
  end
    
  def first(limit = nil)
    if limit
      QueryBuilder.new(self).limit(limit).to_a
    else
      QueryBuilder.new(self).first
    end
  end
  
  def last(limit = nil)
    if limit
      # For multiple records, we need to order and take last N
      all_records = QueryBuilder.new(self).to_a
      all_records.last(limit)
    else
      QueryBuilder.new(self).last
    end
  end
  
  def all
    QueryBuilder.new(self).all
  end
  
  def count
    QueryBuilder.new(self).count
  end
  
  def exists?(conditions = {})
    if conditions.empty?
      count > 0
    else
      where(conditions).exists?
    end
  end

  # Legacy compatibility - maintain old constants for migration
  def ensure_legacy_compatibility
    # Initialize constants if they don't exist (for migration period)
    unless defined?(::JSONRecord::COLUMN_ATTRIBUTES)
      ::JSONRecord.const_set(:COLUMN_ATTRIBUTES, {})
    end
    unless defined?(::JSONRecord::JSON_TABLES)
      ::JSONRecord.const_set(:JSON_TABLES, {})
    end
  end

  # Schema and column management (German precision specifications)
  def columns
    return column_attributes_display if COLUMN_ATTRIBUTES && COLUMN_ATTRIBUTES[table_name]
    
    # Auto-detect from existing documents if no schema defined
    sample_doc = document_storage.find_documents(table_name).first
    return "No documents found" unless sample_doc
    
    detected_schema = sample_doc.keys.map do |key|
      [key, detect_type(sample_doc[key])]
    end
    
    Hash[detected_schema].to_s.gsub("=>", ":").gsub(/\"/, "")
  end

  def column_names
    ensure_legacy_compatibility
    
    if ::JSONRecord::COLUMN_ATTRIBUTES && ::JSONRecord::COLUMN_ATTRIBUTES[table_name]
      ::JSONRecord::COLUMN_ATTRIBUTES[table_name].map { |key| key.first }
    else
      # Safe fallback with error handling
      begin
        sample_doc = document_storage.find_documents(table_name).first
        sample_doc ? sample_doc.keys : ['id']
      rescue => e
        ['id']  # Ultimate fallback
      end
    end
  end
  
  # Vector field definitions (smart sensor specifications)
  def vector_field(field_name, dimensions:, engine: nil)
    @vector_fields ||= {}
    @vector_fields[field_name] = {
      dimensions: dimensions,
      engine: engine || JSONRecord.vector_engine
    }
    
    # Update global configuration
    JSONRecord.configuration.vector_dimensions["#{table_name}_#{field_name}"] = dimensions
    
    # Define accessor methods with correct names (not _vector suffix)
    define_method("#{field_name}=") do |vector|
      instance_variable_set("@#{field_name}", vector)
      @vector_fields_changed ||= []
      @vector_fields_changed << field_name
    end
    
    define_method("#{field_name}") do
      instance_variable_get("@#{field_name}")
    end
  end
  
  def vector_fields
    @vector_fields ||= {}
  end
  
  # Migration and data management (plumber maintenance tools)
  def migrate_from_json_files(json_dir = nil)
    json_dir ||= File.join(File.dirname(__FILE__), '..', '..', 'tables')
    json_file = File.join(json_dir, "#{table_name}.json")
    
    return unless File.exist?(json_file)
    
    puts "Migrating #{table_name} from JSON file to new storage..."
    
    json_data = JSON.parse(File.read(json_file))
    migrated_count = 0
    
    json_data.each do |record|
      document_storage.put_document(table_name, record['id'], record)
      migrated_count += 1
    end
    
    puts "✅ Migrated #{migrated_count} records for #{table_name}"
    migrated_count
  end
  
  def database_stats
    {
      total_documents: document_storage.database_size,
      vector_collections: vector_storage.indexes.keys,
      table_size: document_storage.find_documents(table_name).size
    }
  end
  
  private
  
  # Legacy compatibility - maintain old constants for migration
  def ensure_legacy_compatibility
    # Initialize constants if they don't exist (for migration period)
    unless defined?(::JSONRecord::COLUMN_ATTRIBUTES)
      ::JSONRecord.const_set(:COLUMN_ATTRIBUTES, {})
    end
    unless defined?(::JSONRecord::JSON_TABLES)
      ::JSONRecord.const_set(:JSON_TABLES, {})
    end
  end

  def initialize_columns
    column_names.each { |column| self[column] = nil }
  end

  def find_record(id)
    # Legacy method - redirect to new implementation
    case id
    when Array, Range
      ids = id.is_a?(Range) ? id.to_a : id.flatten
      ids.map { |single_id| find(single_id) }.compact
    else
      find(id)
    end
  end

  def column_attributes_display
    Hash[COLUMN_ATTRIBUTES[table_name].map { |i| [i.first, i.last.to_s] }]
      .to_s.gsub("=>", ":").gsub(/\"/, "")
  end
  
  def detect_type(value)
    case value
    when Integer then Integer
    when Float then Float
    when Array then Array
    when Hash then Hash
    when TrueClass, FalseClass then Boolean
    else String
    end
  end
end
