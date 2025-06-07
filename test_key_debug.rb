require './lib/JSONRecord'

class User < JSONRecord::Base
  column :name, String
  column :age, Integer
end

puts "🔧 Testing key generation..."

storage = User.document_storage

# Test key generation
test_key = storage.send(:document_key, 'users', 1)
puts "Generated key: #{test_key.inspect}"
puts "Key class: #{test_key.class}"

# Test what happens when we store manually
puts "\n🔧 Testing manual storage..."

test_doc = { 'name' => 'Test', 'age' => 30 }
packed_data = MessagePack.pack(test_doc)
puts "Packed data: #{packed_data.inspect}"

# Store with string key
db_handle = storage.instance_variable_get(:@db_handle)
db_handle.put("test_key_string", packed_data)

# Test iteration to see what keys exist
puts "\n🔧 All keys in database:"
db_handle.each do |key, value|
  puts "Key: #{key.inspect} (class: #{key.class})"
  puts "Value size: #{value.size} bytes"
  if key == "test_key_string"
    unpacked = MessagePack.unpack(value)
    puts "Unpacked: #{unpacked.inspect}"
  end
  puts "---"
end
