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
        # Rails applications: use db/ directory (like SQLite)
        Rails.root.join('db', 'jsonrecord.rocksdb').to_s
      elsif development_environment?
        # Development: use local data/ directory (git-ignored)
        File.join(Dir.pwd, 'data', 'jsonrecord.rocksdb')
      elsif ENV['XDG_DATA_HOME']
        # XDG Base Directory specification (Linux/Unix)
        File.join(ENV['XDG_DATA_HOME'], 'jsonrecord', 'jsonrecord.rocksdb')
      elsif ENV['HOME']
        # Fallback: ~/.local/share/jsonrecord (XDG-compliant)
        File.join(ENV['HOME'], '.local', 'share', 'jsonrecord', 'jsonrecord.rocksdb')
      else
        # Last resort: current directory
        File.join(Dir.pwd, 'data', 'jsonrecord.rocksdb')
      end
    end
    
    def development_environment?
      # Heuristics to detect development environment
      return true if Dir.exist?('.git')                    # Git repository
      return true if File.exist?('Gemfile')                # Ruby project
      return true if File.exist?('package.json')           # Node project
      return true if Dir.pwd.include?('/Development/')     # Development directory
      return true if Dir.pwd.include?('/dev/')             # Dev directory
      return true if ENV['RAILS_ENV'] == 'development'     # Rails development
      return true if ENV['NODE_ENV'] == 'development'      # Node development
      
      false
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
    
    def vector_engine=(engine)
      configuration.vector_engine = engine
    end
  end
end
