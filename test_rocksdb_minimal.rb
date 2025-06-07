#!/usr/bin/env ruby

require 'rocksdb'
require 'json'
require 'fileutils'

puts "🔧 MINIMAL ROCKSDB TEST 🔧"
puts

# Clean test environment
test_db_path = "/tmp/test_rocksdb_#{$$}"
FileUtils.rm_rf(test_db_path)

puts "📋 Opening RocksDB directly..."
db = RocksDB.open(test_db_path, create_if_missing: true)

puts "🗄️  Testing basic put/get..."
test_key = "test_key"
test_value = "test_value"

puts "Storing: key='#{test_key}', value='#{test_value}'"
db.put(test_key, test_value)

puts "🔍 Retrieving..."
retrieved_value = db.get(test_key)
puts "Retrieved: #{retrieved_value.inspect}"

puts "📊 Iterating through database..."
db.each do |key, value|
  puts "  Key: #{key.inspect}"
  puts "  Value: #{value.inspect}"
  puts "  ---"
end

puts "🧪 Testing with JSON..."
json_key = "doc:users:1"
json_document = { id: 1, name: "Test User", age: 30 }
json_value = json_document.to_json

puts "Storing JSON: key='#{json_key}', value='#{json_value}'"
db.put(json_key, json_value)

puts "🔍 Retrieving JSON..."
retrieved_json = db.get(json_key)
puts "Retrieved JSON: #{retrieved_json.inspect}"

puts "📊 Final database contents..."
db.each do |key, value|
  puts "  Key: #{key.inspect}"
  puts "  Value: #{value.inspect}"
  puts "  ---"
end

db.close
FileUtils.rm_rf(test_db_path)

puts "✅ Test complete!"
