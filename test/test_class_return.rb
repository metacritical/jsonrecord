#!/usr/bin/env ruby

require_relative 'lib/JSONRecord'

puts "🔧 TESTING CLASS DEFINITION RETURN VALUE 🔧"
puts

puts ">> class User < JSONRecord::Base"
puts ">>   column :name, String"
puts ">>   column :age, Integer"
puts ">> end"

class User < JSONRecord::Base
  column :name, String
  column :age, Integer
end

puts "=> #{User.inspect}"
puts
puts "✅ Expected: User class object"
puts "✅ Actual: #{User.class} (should be Class)"
puts "✅ Class name: #{User.name}"
