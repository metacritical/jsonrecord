#!/usr/bin/env ruby

require_relative 'lib/JSONRecord'

puts "🔧 TESTING IRB SCENARIO EXACTLY 🔧"
puts

class User < JSONRecord::Base
  column :name, String
  column :age, Integer
end

puts "📋 Model Setup:"
puts "Column names: #{User.column_names.inspect}"
puts

# Exactly like IRB
puts "Step 1: user = User.new(name: 'Evan', age: 47)"
user = User.new(name: "Evan", age: 47)
puts "Result: #{user.inspect}"
puts

puts "Step 2: user.save (first time)"
result1 = user.save
puts "Result: #{result1.inspect}"
puts "User after save: #{user.inspect}"
puts

puts "Step 3: User.all (should show the user)"
all_users = User.all
puts "User.all result: #{all_users.inspect}"
puts "Count: #{all_users.length}"
puts

puts "Step 4: user.save (second time - this fails in IRB)"
result2 = user.save
puts "Second save result: #{result2.inspect}"
puts

puts "Step 5: User.all again"
all_users2 = User.all
puts "User.all result: #{all_users2.inspect}"
puts "Count: #{all_users2.length}"
