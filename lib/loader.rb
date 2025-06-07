["../JSONRecord/"].each{ |dir| $LOAD_PATH << File.expand_path(dir,__FILE__) }

require 'version'
require 'fileutils'
require 'json'  # Use standard JSON instead of yajl
require 'active_model'
require 'active_support/inflector'

# New RocksDB + Vector architecture (with fallback)
require 'configuration'

# Storage adapters - load what's available
begin
  require 'storage/rocksdb_adapter'
rescue LoadError => e
  puts "🔧 RocksDB adapter not available: #{e.message}"
end

require 'storage/file_adapter'  # Always load file fallback
require 'storage/vector_adapter'
require 'query_builder'

# Legacy compatibility modules (updated for new architecture)
require 'errors'
require 'json_hash'
require 'json_schema'
require 'class_methods'
require 'module_methods'
require 'instance_methods'
require 'active_model_inclusions'
require 'relation'
require 'meth_missing'

# ActiveRecord integration (Rails compatibility)
begin
  require 'active_record'
  require File.join(File.dirname(__FILE__), 'active_record', 'connection_adapters', 'jsonrecord_adapter')
  require File.join(File.dirname(__FILE__), 'active_record', 'jsonrecord_extensions')
  puts "🔧 ActiveRecord adapter loaded - JsonRecord ready for Rails integration!"
rescue LoadError => e
  puts "🔧 ActiveRecord not found - using standalone JsonRecord mode"
end
