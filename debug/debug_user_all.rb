#!/usr/bin/env ruby

require_relative 'lib/JSONRecord'

puts "🔧 DEEP DEBUGGING USER.ALL ISSUE 🔧"
puts

class User < JSONRecord::Base
  column :name, String
  column :age, Integer
end

puts "📋 Model Setup:"
puts "Table name: #{User.table_name}"
puts "Column names: #{User.column_names.inspect}"
puts

# Create and save a user
user = User.new(name: "Evan", age: 47)
puts "🗄️  Saving user..."
result = user.save
puts "Save result: #{result.inspect}"
puts "User ID: #{user.id}"
puts

# Check storage directly
storage = User.document_storage
puts "🔍 Direct storage check:"
puts "Storage class: #{storage.class}"

# Get all documents directly from storage
puts "📊 All documents in storage (direct call):"
all_docs = storage.find_documents(User.table_name)
puts "Direct documents: #{all_docs.inspect}"
puts "Direct count: #{all_docs.length}"
puts

# Check QueryBuilder
puts "🔎 QueryBuilder debugging:"
query_builder = User.where({})  # Empty where to get QueryBuilder
puts "QueryBuilder class: #{query_builder.class}"

# Check what execute_document_only_query returns
puts "📋 QueryBuilder.execute_query:"
raw_results = query_builder.send(:execute_query)
puts "Raw results: #{raw_results.inspect}"
puts "Raw count: #{raw_results.length}"
puts

# Test User.all specifically
puts "🧪 User.all debugging:"
all_users = User.all
puts "User.all result: #{all_users.inspect}"
puts "User.all count: #{all_users.length}"
puts "User.all class: #{all_users.class}"
