require_relative '../lib/JSONRecord'

class User < JSONRecord::Base
  column :name, String
  column :age, Integer
end

puts "🔧 Testing JSONRecord step by step..."

# Test 1: Create user
user = User.new(name: "Evan", age: 47)
puts "User created: #{user.name}, #{user.age}"

# Test 2: Save user
result = user.save
puts "Save result: #{result}"
puts "User ID after save: #{user.id}"

# Test 3: Check if user is in storage
storage = User.document_storage
all_docs = storage.find_documents('users')
puts "Total documents in storage: #{all_docs.size}"
puts "Documents: #{all_docs.inspect}"

# Test 4: Try simple query
users_with_age = storage.find_documents('users', { 'age' => 47 })
puts "Users with age 47: #{users_with_age.size}"

# Test 5: Try complex query
users_older = storage.find_documents('users', { 'age' => { gte: 40 } })
puts "Users with age >= 40: #{users_older.size}"

# Test 6: ActiveRecord-style query
ar_users = User.where(age: 47).to_a
puts "ActiveRecord query (age=47): #{ar_users.size}"

ar_users_complex = User.where(age: { gte: 40 }).to_a
puts "ActiveRecord query (age>=40): #{ar_users_complex.size}"
