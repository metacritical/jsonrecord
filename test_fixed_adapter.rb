#!/usr/bin/env ruby

# Test AFTER fixing RocksDB parameter swap bug
# This should now work properly

require './lib/JSONRecord'

puts "🔧 TESTING FIXED ROCKSDB ADAPTER 🔧"
puts

# Define simple test model
class User < JSONRecord::Base
  column :name, String
  column :age, Integer
end

puts "1. Creating test users..."
user1 = User.new(name: "TestUser1", age: 30)
result1 = user1.save
puts "   User1 saved: #{result1 ? 'SUCCESS' : 'FAILED'} (ID: #{user1.id})"

user2 = User.new(name: "TestUser2", age: 35) 
result2 = user2.save
puts "   User2 saved: #{result2 ? 'SUCCESS' : 'FAILED'} (ID: #{user2.id})"

puts "\n2. Testing User.all (should find documents)..."
all_users = User.all.to_a
puts "   Found #{all_users.count} users"
all_users.each do |user|
  puts "   - #{user['name']}, Age: #{user['age']}"
end

puts "\n3. Testing User.find by ID..."
if user1.id
  found_user = User.find(user1.id)
  if found_user
    puts "   ✅ Found user1: #{found_user['name']}"
  else
    puts "   ❌ Could not find user1"
  end
end

puts "\n4. Testing User.where query..."
query_results = User.where(name: "TestUser1").to_a
puts "   Query found #{query_results.count} users"

puts "\n🔧 Test complete!"
puts "   Status: #{all_users.count > 0 ? '✅ FIXED!' : '❌ Still broken'}"
