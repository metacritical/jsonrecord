# JSONRecord Configuration Examples

## Basic Usage

```ruby
# Simple configuration
JSONRecord.configure do |config|
  config.database_path = '/path/to/your/database'
  config.vector_engine = :faiss  # or :simple, :annoy
  config.enable_compression = true
end
```

## Rails Integration

JSONRecord automatically detects Rails and stores data in `db/jsonrecord.rocksdb` (similar to SQLite).

### Custom Rails Configuration

```ruby
# config/initializers/jsonrecord.rb
JSONRecord.configure do |config|
  config.database_path = Rails.root.join('storage', 'jsonrecord.rocksdb')
  config.vector_engine = :faiss
  config.rocksdb_options = {
    create_if_missing: true,
    write_buffer_size: 64.megabytes,
    max_open_files: 1000
  }
end
```

### Environment-Specific Configuration

```ruby
# config/initializers/jsonrecord.rb
rails_env = Rails.env

database_paths = {
  'development' => Rails.root.join('storage', 'development.jsonrecord'),
  'test' => Rails.root.join('storage', 'test.jsonrecord'), 
  'production' => '/var/lib/myapp/production.jsonrecord'
}

JSONRecord.configure do |config|
  config.database_path = database_paths[rails_env]
  config.vector_engine = rails_env == 'production' ? :faiss : :simple
  config.enable_compression = rails_env == 'production'
end
```

## Unix/Linux XDG Compliance

JSONRecord follows XDG Base Directory specification:

- **With XDG_DATA_HOME**: `$XDG_DATA_HOME/jsonrecord/jsonrecord.rocksdb`
- **Without XDG_DATA_HOME**: `~/.local/share/jsonrecord/jsonrecord.rocksdb`
- **Development**: `./data/jsonrecord.rocksdb` (git-ignored)

## Custom Storage Locations

```ruby
# System-wide database
JSONRecord.configure do |config|
  config.database_path = '/var/lib/jsonrecord/app.rocksdb'
end

# User-specific database  
JSONRecord.configure do |config|
  config.database_path = File.join(Dir.home, '.myapp', 'database.rocksdb')
end

# Environment variable
JSONRecord.configure do |config|
  config.database_path = ENV['JSONRECORD_DATABASE_PATH'] || 
                         File.join(Dir.pwd, 'data', 'jsonrecord.rocksdb')
end
```

## Performance Tuning

```ruby
JSONRecord.configure do |config|
  config.rocksdb_options = {
    create_if_missing: true,
    write_buffer_size: 128.megabytes,      # Larger write buffer
    max_write_buffer_number: 4,            # More write buffers
    max_open_files: 10000,                 # More file descriptors
    compression: 'snappy',                 # Enable compression
    block_cache_size: 256.megabytes        # Larger block cache
  }
  config.index_cache_size = 1_000_000      # More index entries in memory
end
```

## Security Configuration

```ruby
# Encrypted database path (with external encryption)
JSONRecord.configure do |config|
  config.database_path = '/encrypted/volume/jsonrecord.rocksdb'
end

# Read-only mode (for analytics)
JSONRecord.configure do |config|
  config.rocksdb_options = {
    read_only: true,
    create_if_missing: false
  }
end
```
