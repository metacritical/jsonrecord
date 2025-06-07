#!/usr/bin/env ruby

puts "🔧 RUSSIAN PLUMBER FINAL API TEST 🔧"
puts "Testing ActiveRecord-style interface..."
puts

begin
  require './lib/JSONRecord'
  
  class User < JSONRecord::Base
    column :name, String
    column :age, Integer
  end
  
  puts "✅ User model defined successfully!"
  puts "Storage: #{User.document_storage.class}"  # Should show FileAdapter
  
  user = User.new(name: "Evan", age: 47)
  user.save
  puts "✅ User saved with ID: #{user.id}"
  
  # Test new query features
  users = User.where(age: { gte: 40 }).to_a
  puts "✅ Users 40+: #{users.size}"
  
  # Test more features
  all_users = User.all.to_a
  puts "✅ Total users: #{all_users.size}"
  
  # Test find
  found_user = User.find(user.id)
  puts "✅ Found user: #{found_user.name}, age #{found_user.age}"
  
  puts "\n🚀 ACTIVERECORD API SUCCESS!"
  puts "JSONRecord modernization complete and working!"
  
rescue => e
  puts "\n❌ ERROR: #{e.message}"
  puts "🔧 Error type: #{e.class}"
  puts "Stack trace:"
  puts e.backtrace.first(10).join("\n")
  
  puts "\n🔧 DEBUGGING INFO:"
  puts "This helps identify remaining issues..."
end
