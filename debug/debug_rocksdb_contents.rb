#!/usr/bin/env ruby

# Debug actual RocksDB storage contents

require_relative '../lib/JSONRecord'

puts "🔧 DEBUG ACTUAL ROCKSDB CONTENTS 🔧"
puts

# Clean database
system("rm -rf data/jsonrecord*")

class User < JSONRecord::Base
  column :name, String
  column :age, Integer
end

# Force fresh storage
JSONRecord::Base.class_variable_set(:@@document_storage, nil)

puts "1. Creating user and checking storage..."
user = User.new(name: "RocksDebug", age: 77)
result = user.save
puts "   Save result: #{result ? 'SUCCESS' : 'FAILED'} (ID: #{user.id})"

storage = User.document_storage
puts "   Storage class: #{storage.class}"

if storage.is_a?(JSONRecord::Storage::RocksDBAdapter)
  puts "\n2. Raw RocksDB iteration..."
  count = 0
  storage.db_handle.each do |key, value|
    count += 1
    puts "   #{count}. KEY='#{key}' (#{key.class}) → VALUE='#{value}' (#{value.class})"
    
    # Check our fixed iteration logic
    prefix = "doc:users:"
    if value && value.is_a?(String) && value.start_with?(prefix)
      puts "      ✅ VALUE matches expected key pattern!"
      begin
        document = MessagePack.unpack(key)
        puts "      Document from KEY: #{document}"
      rescue => e
        puts "      ❌ Failed to parse KEY as MessagePack: #{e.message}"
      end
    else
      puts "      ❌ VALUE doesn't match expected pattern"
    end
    
    break if count >= 5
  end
  
  puts "\n3. Testing our all_documents method..."
  documents = storage.send(:all_documents, "users")
  puts "   all_documents returned: #{documents.count} documents"
  documents.each_with_index do |doc, i|
    puts "   #{i+1}. #{doc}"
  end
else
  puts "   Using FileAdapter - checking files..."
  files = Dir.glob("data/jsonrecord/users/*.json")
  puts "   Files found: #{files}"
end

puts "\n🔧 Debug complete!"
