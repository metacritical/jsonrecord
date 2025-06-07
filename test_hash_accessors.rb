#!/usr/bin/env ruby

require './lib/JSONRecord'

puts "🔧 TESTING HASH METHOD ACCESSORS 🔧"
puts

class User < JSONRecord::Base
  column :name, String
  column :age, Integer
  column :email, String
end

puts "1. Creating and saving user..."
user = User.new(name: "TestUser", age: 30)
user.save
puts "   User saved: #{user.class} with ID #{user.id}"

puts "\n2. Testing User.find..."
found_user = User.find(user.id)
puts "   Found user class: #{found_user.class}"
puts "   Found user data: #{found_user.inspect}"

puts "\n3. Testing getter methods..."
begin
  name = found_user.name
  age = found_user.age
  puts "   ✅ Getters work: name=#{name}, age=#{age}"
rescue => e
  puts "   ❌ Getter error: #{e.message}"
end

puts "\n4. Testing setter methods..."
begin
  found_user.age = 31
  found_user.email = "test@example.com"
  puts "   ✅ Setters work: age=#{found_user.age}, email=#{found_user.email}"
rescue => e
  puts "   ❌ Setter error: #{e.message}"
end

puts "\n5. Testing save after update..."
begin
  found_user.save
  puts "   ✅ Save after update works"
rescue => e
  puts "   ❌ Save error: #{e.message}"
end

puts "\n🔧 Test complete!"
