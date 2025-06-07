#!/usr/bin/env ruby

require './lib/JSONRecord'

class User < JSONRecord::Base
  column :name, String
  column :age, Integer
end

puts "=== JSONRecord Basic Test ==="
puts "Model loaded successfully"

user = User.new(name: 'TestUser', age: 30)
puts "User created: #{user.name}, #{user.age}"

result = user.save
puts "Save result: #{result ? 'success' : 'failed'}"
puts "User ID: #{user.id}"

# Test retrieval
if user.id
  found_user = User.find(user.id)
  puts "Found user: #{found_user.name}, #{found_user.age}"
end

puts "=== Test Complete ==="
