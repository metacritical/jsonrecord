module JSONRecord
  class Configuration
    attr_accessor :database_path, :vector_engine, :vector_dimensions, 
                  :rocksdb_options, :enable_compression, :index_cache_size
    
    def initialize
      @database_path = default_database_path
      @vector_engine = :simple  # Options: :simple, :annoy, :faiss
      @vector_dimensions = {}
      @rocksdb_options = default_rocksdb_options
      @enable_compression = true
      @index_cache_size = 100_000
    end
    
    private
    
    def default_database_path
      if defined?(Rails) && Rails.respond_to?(:root)
        Rails.root.join('db', 'jsonrecord.rocksdb')
      else
        File.join(Dir.pwd, 'data', 'jsonrecord.rocksdb')
      end
    end
    
    def default_rocksdb_options
      {
        create_if_missing: true
        # Keep minimal options for maximum compatibility
        # Advanced options can be added after basic functionality works
      }
    end
  end
  
  class << self
    def configuration
      @configuration ||= Configuration.new
    end
    
    def configure
      yield(configuration) if block_given?
    end
    
    # Plumber's helper methods
    def database_path
      configuration.database_path
    end
    
    def vector_engine
      configuration.vector_engine
    end
  end
end
