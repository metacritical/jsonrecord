#!/usr/bin/env ruby

# Quick test without ActiveModel dependencies
$LOAD_PATH << File.expand_path('lib', __dir__)

# Minimal test - just load the column method fix
require_relative 'lib/JSONRecord/json_schema'

puts "🔧 TESTING COLUMN METHOD FIX 🔧"
puts

# Create test class to verify column method return value
class TestUser < JSONRecord::Base
  puts "Before column definitions..."
  result1 = column :name, String
  puts "First column returned: #{result1.inspect}"
  result2 = column :age, Integer  
  puts "Second column returned: #{result2.inspect}"
  puts "Final class definition result should be TestUser class..."
end

puts "=> #{TestUser.inspect}"
puts "✅ TestUser.class = #{TestUser.class}"
puts "✅ TestUser.name = #{TestUser.name}"
