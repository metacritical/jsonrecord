# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'JSONRecord/version'

Gem::Specification.new do |gem|
  gem.name          = "JSONRecord"
  gem.version       = JSONRecord::VERSION
  gem.authors       = ["Pankaj Doharey"]
  gem.email         = ["pankajdoharey@gmail.com"]
  gem.description   = %q{High-performance document database with RocksDB backend, vector similarity search, and complete ActiveRecord integration}
  gem.summary       = %q{JSONRecord is a modern document storage system that works as both a standalone database and a complete ActiveRecord adapter. Built on RocksDB + Vector Search for optimal performance, it provides seamless Rails integration with powerful similarity search capabilities.}
  gem.homepage      = "https://github.com/metacritical/jsonrecord"
  gem.license       = "MIT"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  
  # Minimum Ruby version for modern features
  gem.required_ruby_version = ">= 2.7.0"
  
  # Core dependencies for JSONRecord v2.0 - Production ready
  gem.add_dependency "activesupport", ">= 6.0", "< 8.0"
  gem.add_dependency "activemodel", ">= 6.0", "< 8.0"
  gem.add_dependency "msgpack", "~> 1.0"       # Binary serialization
  gem.add_dependency "matrix"                   # Vector operations
  
  # Storage backend (RocksDB is primary, FileAdapter fallback)
  gem.add_dependency "rocksdb-ruby", "~> 1.0"
  
  # Vector similarity search engines
  gem.add_dependency "annoy-rb", "~> 0.7"     # Spotify's Annoy algorithm
  
  # Optional Rails integration (for ActiveRecord adapter)
  gem.add_dependency "activerecord", ">= 6.0", "< 8.0"
  
  # Development dependencies
  gem.add_development_dependency "rake", "~> 13.0"
  gem.add_development_dependency "minitest", "~> 5.0"
  gem.add_development_dependency "minitest-reporters", "~> 1.5"
  gem.add_development_dependency "bundler", ">= 2.0"
  
  # Optional performance dependencies (can be added by users)
  # gem.add_dependency "faiss-ruby"  # Facebook's FAISS (if Ruby bindings available)
  
  # Metadata
  gem.metadata = {
    "bug_tracker_uri"   => "https://github.com/metacritical/jsonrecord/issues",
    "changelog_uri"     => "https://github.com/metacritical/jsonrecord/blob/master/CHANGELOG.md",
    "documentation_uri" => "https://github.com/metacritical/jsonrecord/blob/master/README.md",
    "homepage_uri"      => "https://github.com/metacritical/jsonrecord",
    "source_code_uri"   => "https://github.com/metacritical/jsonrecord",
    "wiki_uri"          => "https://github.com/metacritical/jsonrecord/wiki"
  }
  
  # Post-install message
  gem.post_install_message = <<~MSG
    🔧 JSONRecord v#{JSONRecord::VERSION} installed successfully! 🔧
    
    ⚡ Features:
    • RocksDB backend for 10-100x performance 
    • Vector similarity search (Simple/Annoy/Faiss engines)
    • Complete ActiveRecord adapter for Rails integration
    • Drop-in replacement for SQLite with vector capabilities
    
    📚 Quick Start:
    • Standalone: class User < JSONRecord::Base; end
    • Rails: Configure in database.yml with adapter: jsonrecord
    
    📖 Documentation: https://github.com/metacritical/jsonrecord
    🐛 Issues: https://github.com/metacritical/jsonrecord/issues
    
    Happy coding with German precision engineering! 🚀
  MSG
end
