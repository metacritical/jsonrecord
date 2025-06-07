#!/usr/bin/env ruby

# Simple isolated test of User.all fix

require_relative '../lib/JSONRecord'

puts "🔧 ISOLATED USER.ALL TEST 🔧"
puts

# Clean database
system("rm -rf data/jsonrecord*")

class User < JSONRecord::Base
  column :name, String
  column :age, Integer
end

puts "1. Creating fresh user..."
user = User.new(name: "IsolatedTest", age: 99)
result = user.save
puts "   Save result: #{result ? 'SUCCESS' : 'FAILED'} (ID: #{user.id})"

puts "\n2. Testing User.all..."
all_users = User.all.to_a
puts "   User.all count: #{all_users.count}"
if all_users.count > 0
  first_user = all_users.first
  puts "   First user class: #{first_user.class}"
  puts "   First user data: #{first_user.inspect}"
  
  # Test accessor methods
  begin
    name = first_user.name
    puts "   first_user.name: #{name}"
  rescue => e
    puts "   ERROR accessing name: #{e.message}"
  end
end

puts "\n3. Testing User.count..."
count = User.count
puts "   User.count: #{count}"

puts "\n🔧 Test complete! Status: #{all_users.count > 0 ? 'WORKING' : 'BROKEN'}"
