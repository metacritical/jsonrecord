#!/usr/bin/env ruby

require_relative '../lib/JSONRecord'

puts "🔧 TESTING QUERYBUILDER METHOD DELEGATION 🔧"
puts

class User < JSONRecord::Base
  column :name, String
  column :age, Integer
end

# Create test data
3.times do |i|
  user = User.new(name: "User#{i+1}", age: 20 + i)
  user.save
end

puts "1. Testing User.limit(2)..."
begin
  limited_users = User.limit(2).to_a
  puts "   ✅ User.limit(2) works: #{limited_users.count} users"
  limited_users.each { |u| puts "   - #{u['name']}" }
rescue => e
  puts "   ❌ Error: #{e.message}"
end

puts "\n2. Testing User.offset(1).limit(1)..."
begin
  offset_users = User.offset(1).limit(1).to_a
  puts "   ✅ User.offset(1).limit(1) works: #{offset_users.count} users"
  offset_users.each { |u| puts "   - #{u['name']}" }
rescue => e
  puts "   ❌ Error: #{e.message}"
end

puts "\n3. Testing User.order(:name)..."
begin
  ordered_users = User.order(:name).to_a
  puts "   ✅ User.order(:name) works: #{ordered_users.count} users"
  ordered_users.each { |u| puts "   - #{u['name']}" }
rescue => e
  puts "   ❌ Error: #{e.message}"
end

puts "\n🔧 Test complete!"
