#!/usr/bin/env ruby

# Test JSONHash in isolation
require './lib/JSONRecord/json_hash'

puts "🔧 TESTING JSONHASH IN ISOLATION 🔧"
puts

class TestHash < JSONRecord::JSONHash
end

hash = TestHash.new
hash["name"] = "Test"
hash["age"] = 30

puts "1. Testing getter method_missing..."
begin
  name = hash.name
  puts "   ✅ Getter works: name = #{name}"
rescue => e
  puts "   ❌ Getter error: #{e.message}"
end

puts "2. Testing setter method_missing..."
begin
  hash.age = 31
  puts "   ✅ Setter works: age = #{hash.age}"
rescue => e
  puts "   ❌ Setter error: #{e.message}"
end

puts "3. Direct test of method_missing..."
begin
  result = hash.__send__(:method_missing, :age=, 32)
  puts "   Direct method_missing result: #{result}"
  puts "   Age after direct call: #{hash.age}"
rescue => e
  puts "   ❌ Direct method_missing error: #{e.message}"
end

puts "\n🔧 Test complete!"
