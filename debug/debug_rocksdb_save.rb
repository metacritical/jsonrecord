#!/usr/bin/env ruby

require_relative 'lib/JSONRecord'

puts "🔧 DEBUGGING ROCKSDB SAVE PROCESS 🔧"
puts

class User < JSONRecord::Base
  column :name, String
  column :age, Integer
end

# Get access to storage and enable debug
ENV['DEBUG'] = 'true'

puts "📋 Creating user..."
user = User.new(name: "Evan", age: 47)
puts "User before save: #{user.inspect}"
puts

puts "🗄️  Saving with debug enabled..."
result = user.save
puts "Save result: #{result.inspect}"
puts "User after save: #{user.inspect}"
puts

# Check what the storage actually contains
storage = User.document_storage
puts "🔍 Storage inspection:"
puts "Storage class: #{storage.class}"

if storage.respond_to?(:db_handle)
  puts "📊 Iterating through all RocksDB keys:"
  storage.db_handle.each do |key, value|
    puts "  Key: #{key.inspect}"
    puts "  Value: #{value.inspect}"
    puts "  Value length: #{value ? value.length : 'nil'}"
    
    # Try to parse value as JSON
    begin
      parsed = JSON.parse(value)
      puts "  Parsed JSON: #{parsed.inspect}"
    rescue JSON::ParserError => e
      puts "  JSON parse error: #{e.message}"
    end
    puts "  ---"
  end
end

puts "🔎 Testing find_documents with table name: #{User.table_name}"
docs = storage.find_documents(User.table_name)
puts "Found documents: #{docs.inspect}"
