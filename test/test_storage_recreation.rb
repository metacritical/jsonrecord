#!/usr/bin/env ruby

# Test with forcing storage adapter recreation

require_relative '../lib/JSONRecord'

puts "🔧 TEST WITH STORAGE ADAPTER RECREATION 🔧"
puts

# Clean database
system("rm -rf data/jsonrecord*")

class User < JSONRecord::Base
  column :name, String
  column :age, Integer
end

puts "1. Forcing storage adapter recreation..."
# Clear the class variable to force recreation
JSONRecord::Base.class_variable_set(:@@document_storage, nil)

puts "2. Creating fresh user..."
user = User.new(name: "RecreateTest", age: 88)
result = user.save
puts "   Save result: #{result ? 'SUCCESS' : 'FAILED'} (ID: #{user.id})"

puts "3. Testing User.all..."
all_users = User.all.to_a
puts "   User.all count: #{all_users.count}"

puts "4. Checking storage adapter directly..."
storage = User.document_storage
puts "   Storage class: #{storage.class}"
documents = storage.find_documents("users")
puts "   Direct storage find_documents: #{documents.count} documents"

puts "\n🔧 Test complete! Status: #{all_users.count > 0 ? 'WORKING' : 'BROKEN'}"
