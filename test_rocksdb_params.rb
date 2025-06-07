#!/usr/bin/env ruby
# Debug RocksDB parameter order

require './lib/JSONRecord'

class User < JSONRecord::Base
  column :name, String
end

puts "=== RocksDB Parameter Debug ==="

storage = User.document_storage
db_handle = storage.instance_variable_get(:@db_handle)

# Test manual storage
puts "1. Testing manual RocksDB operations..."

test_key = "test:manual:1"
test_value = "simple test value"

puts "Storing: key='#{test_key}' value='#{test_value}'"
db_handle.put(test_key, test_value)

# Check what got stored
puts "\n2. Checking stored data..."
retrieved = db_handle.get(test_key)
puts "Retrieved: #{retrieved.inspect}"

# Test with MessagePack
puts "\n3. Testing with MessagePack..."
test_doc = { "name" => "TestDoc", "id" => 999 }
packed_doc = MessagePack.pack(test_doc)

test_key2 = "test:msgpack:999"
puts "Storing: key='#{test_key2}' packed_size=#{packed_doc.size}"
db_handle.put(test_key2, packed_doc)

retrieved2 = db_handle.get(test_key2)
puts "Retrieved size: #{retrieved2&.size}"
if retrieved2
  unpacked = MessagePack.unpack(retrieved2)
  puts "Unpacked: #{unpacked.inspect}"
end

# Test the exact pattern from put_document
puts "\n4. Testing put_document pattern..."
key = storage.send(:document_key, 'users', 123)
document = { "name" => "PatternTest", "id" => 123 }
packed_data = MessagePack.pack(document)

puts "Key: #{key.inspect}"
puts "Packed size: #{packed_data.size}"

db_handle.put(key, packed_data)

# Check all keys
puts "\n5. All keys in database:"
db_handle.each do |k, v|
  puts "Key: #{k.inspect} (#{k.length} chars)"
  puts "Value size: #{v&.size || 0} bytes"
  if k == test_key || k == test_key2 || k == key
    puts "  -> This is our test key!"
  end
  puts "---"
end

puts "\n=== Debug Complete ==="
