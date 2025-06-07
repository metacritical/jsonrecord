#!/usr/bin/env ruby

# Debugging RocksDB iteration behavior

require './lib/JSONRecord'

puts "🔧 DEBUGGING ROCKSDB ITERATION 🔧"
puts

class User < JSONRecord::Base
  column :name, String
  column :age, Integer
end

puts "1. Creating test user..."
user = User.new(name: "DebugUser", age: 42)
result = user.save
puts "   Save result: #{result}, ID: #{user.id}"

puts "\n2. Direct RocksDB inspection..."
storage = User.document_storage
if storage.respond_to?(:db_handle)
  puts "   Iterating through raw RocksDB data:"
  count = 0
  storage.db_handle.each do |key, value|
    count += 1
    puts "   #{count}. KEY: '#{key}' → VALUE: '#{value}'"
    puts "      KEY type: #{key.class}, VALUE type: #{value.class}"
    
    # Try to parse key as MessagePack
    begin
      parsed_key = MessagePack.unpack(key)
      puts "      KEY parsed as MessagePack: #{parsed_key}"
    rescue => e
      puts "      KEY not MessagePack: #{e.message}"
    end
    
    # Check if value looks like our expected key pattern
    if value && value.is_a?(String) && value.start_with?("doc:users:")
      puts "      ✅ VALUE matches expected key pattern!"
    end
    
    puts
    break if count >= 5  # Limit output
  end
  
  puts "   Total entries found: #{count}"
else
  puts "   Not using RocksDB storage"
end

puts "\n3. Testing User.all..."
all_users = User.all.to_a
puts "   User.all returned: #{all_users.count} users"

puts "\n🔧 Debug complete!"
