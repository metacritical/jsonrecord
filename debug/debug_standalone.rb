#!/usr/bin/env ruby

require_relative 'lib/JSONRecord'

puts "🔧 DEBUGGING STANDALONE MODE ISSUES 🔧"
puts

class User < JSONRecord::Base
  column :name, String
  column :age, Integer
end

puts "📋 Model Definition:"
puts "Table name: #{User.table_name}"
puts "Column names: #{User.column_names.inspect}"
puts "Storage: #{User.document_storage.class}"
puts

puts "🔧 Testing Save Process:"
user = User.new(name: "Evan", age: 47)
puts "New user: #{user.inspect}"
puts "Has ID before save: #{user.id.inspect}"

puts "\n🗄️  Attempting to save..."
result = user.save
puts "Save result: #{result.inspect}"
puts "User after save: #{user.inspect}"
puts "Has ID after save: #{user.id.inspect}"

puts "\n🔍 Direct Storage Check:"
storage = User.document_storage
puts "Storage class: #{storage.class}"
puts "Database path: #{storage.respond_to?(:db_path) ? storage.db_path : 'N/A'}"

# Check if document was actually stored
if user.id
  puts "\n📋 Direct document lookup:"
  direct_doc = storage.get_document(User.table_name, user.id)
  puts "Direct lookup result: #{direct_doc.inspect}"
end

puts "\n📊 All documents in storage:"
all_docs = storage.find_documents(User.table_name)
puts "All documents: #{all_docs.inspect}"
puts "Document count: #{all_docs.length}"

puts "\n🔎 User.all query:"
all_users = User.all
puts "User.all result: #{all_users.inspect}"
puts "User.all count: #{all_users.respond_to?(:length) ? all_users.length : 'not array'}"

puts "\n🔧 Testing User.count:"
count = User.count
puts "User.count: #{count}"

puts "\n🛠️  Storage database info:"
if storage.respond_to?(:database_size)
  puts "Database size: #{storage.database_size}"
end

if storage.respond_to?(:list_tables)
  puts "Tables in database: #{storage.list_tables.inspect}"
end

puts "\n✅ Debug complete!"
