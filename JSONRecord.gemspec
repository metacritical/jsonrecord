# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'JSONRecord/version'

Gem::Specification.new do |gem|
  gem.name          = "JSONRecord"
  gem.version       = JSONRecord::VERSION
  gem.authors       = ["Pankaj Doharey"]
  gem.email         = ["pankajdoharey@gmail.com"]
  gem.description   = %q{JSON Data storage in ruby}
  gem.summary       = %q{JSONRecord is a minimal document storage for rails, with an active record style query interface.}
  gem.homepage      = "http://jsondb.codemismatch.com"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  # Modern dependencies for JSONRecord v2.0 - RocksDB required
  gem.add_dependency "activesupport", ">= 6.0"
  gem.add_dependency "activemodel", ">= 6.0"
  gem.add_dependency "rocksdb-ruby", "~> 1.0"  # Hard requirement
  gem.add_dependency "msgpack", "~> 1.0"
  gem.add_dependency "matrix"  # For vector operations
  
  # Note: Vector similarity engines like annoy-rb can be added optionally
  # Users can add to their Gemfile: gem 'annoy-rb', require: false
end
