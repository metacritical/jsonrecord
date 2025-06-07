#!/usr/bin/env ruby
# Focused test to debug specific issues

require_relative '../lib/JSONRecord'

puts "=== Debugging JSONRecord Issues ==="

class User < JSONRecord::Base
  column :name, String
  column :age, Integer
  column :skills, Array
  vector_field :profile_embedding, dimensions: 4
end

puts "1. Testing column definition..."
puts "Column names: #{User.column_names.inspect}"

puts "\n2. Testing basic CRUD..."
user = User.new(name: "TestUser", age: 30, skills: ["ruby", "python"])
puts "User created: #{user.inspect}"
puts "User class: #{user.class}"

result = user.save
puts "Save result: #{result.inspect}"
puts "User after save: #{user.inspect}"

puts "\n3. Testing queries..."
all_users = User.all.to_a
puts "All users count: #{all_users.length}"

users_found = User.where(name: "TestUser").to_a  
puts "Users with name TestUser: #{users_found.length}"

puts "\n4. Testing vector fields..."
begin
  puts "Vector fields defined: #{User.vector_fields.inspect}"
  
  # Test vector field assignment
  user.profile_embedding = [0.1, 0.2, 0.3, 0.4]
  puts "Vector assigned: #{user.profile_embedding.inspect}"
rescue => e
  puts "Vector field error: #{e.message}"
  puts "Available methods: #{user.methods.grep(/embedding/).inspect}"
end

puts "\n5. Testing method access..."
puts "User name via method: #{user.name rescue 'ERROR'}"
puts "User name via hash: #{user['name']}"
puts "User age via method: #{user.age rescue 'ERROR'}"  
puts "User age via hash: #{user['age']}"

puts "\n=== Debug Complete ==="
