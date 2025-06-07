#!/usr/bin/env ruby
# Debug the all_documents query issue

require_relative '../lib/JSONRecord'

class User < JSONRecord::Base
  column :name, String
  column :age, Integer
end

puts "=== Debugging Query Issues ==="

# Create a user
user = User.new(name: "QueryTest", age: 25)
user.save
puts "User saved with ID: #{user.id}"

# Test storage directly
storage = User.document_storage
puts "Storage class: #{storage.class}"

# Test all_documents method
puts "\n1. Testing all_documents directly..."
all_docs = storage.send(:all_documents, 'users')
puts "all_documents result: #{all_docs.length} documents"
puts "Documents: #{all_docs.inspect}"

# Test find_documents with no conditions
puts "\n2. Testing find_documents(empty)..."
find_empty = storage.find_documents('users')
puts "find_documents(empty) result: #{find_empty.length} documents"

# Test find_documents with condition
puts "\n3. Testing find_documents(condition)..."
find_with_condition = storage.find_documents('users', { 'name' => 'QueryTest' })
puts "find_documents(condition) result: #{find_with_condition.length} documents"

# Test RocksDB iteration directly
puts "\n4. Testing RocksDB iteration..."
db_handle = storage.instance_variable_get(:@db_handle)
prefix = "doc:users:"
found_keys = []

begin
  db_handle.each do |key, value|
    puts "  Found key: #{key.inspect}"
    if key.start_with?(prefix)
      found_keys << key
      puts "    -> Matches prefix!"
    end
  end
  puts "Total keys with prefix: #{found_keys.length}"
rescue => e
  puts "Iteration error: #{e.message}"
end

puts "\n=== Debug Complete ==="
