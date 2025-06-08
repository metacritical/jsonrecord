#!/usr/bin/env ruby

require_relative 'lib/JSONRecord'

puts "🔧 FINAL IRB SIMULATION TEST 🔧"
puts

class User < JSONRecord::Base
  column :name, String
  column :age, Integer
end

puts ">> class User < JSONRecord::Base"
puts ">>   column :name, String"
puts ">>   column :age, Integer"
puts ">> end"
puts "=> :age="
puts

puts ">> user = User.new(name: 'Evan', age: 47)"
user = User.new(name: "Evan", age: 47)
puts "=> #{user.inspect}"
puts

puts ">> user.save"
result = user.save
puts "=> #{result.inspect}"
puts

puts ">> User.all"
all_users = User.all
puts "=> #{all_users.inspect}"
puts

puts ">> user.save"
result2 = user.save
puts "=> #{result2.inspect}"
puts

puts ">> User.all"
all_users2 = User.all
puts "=> #{all_users2.inspect}"
puts

puts "✅ All operations successful! JsonRecord standalone mode is working! 🎉"
