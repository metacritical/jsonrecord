#!/usr/bin/env ruby
# Test RocksDB parameter order

require 'rocksdb'
require 'fileutils'

puts "=== RocksDB Parameter Order Test ==="

# Clean start
FileUtils.rm_rf('/tmp/test_rocksdb')
db = RocksDB.open('/tmp/test_rocksdb', create_if_missing: true)

puts "1. Testing put(key, value) order..."
db.put("key1", "value1")
db.put("key2", "value2")

puts "2. Checking retrieval..."
puts "get('key1'): #{db.get('key1').inspect}"
puts "get('key2'): #{db.get('key2').inspect}"

puts "3. Checking all keys..."
db.each do |key, value|
  puts "Key: #{key.inspect} => Value: #{value.inspect}"
end

db.close
FileUtils.rm_rf('/tmp/test_rocksdb')

puts "\n=== Test Complete ==="
puts "If this shows correct key-value pairs, the issue is in our code, not RocksDB."
