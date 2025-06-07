#!/usr/bin/env ruby

# Debug the QueryBuilder -> Storage chain

require './lib/JSONRecord'

puts "🔧 DEBUGGING QUERY BUILDER -> STORAGE CHAIN 🔧"
puts

class User < JSONRecord::Base
  column :name, String
  column :age, Integer
end

puts "1. Testing storage.find_documents directly..."
storage = User.document_storage
table_name = User.table_name
puts "   Storage class: #{storage.class}"
puts "   Table name: #{table_name}"

documents = storage.find_documents(table_name)
puts "   Direct find_documents returned: #{documents.count} documents"
documents.each_with_index do |doc, i|
  puts "   #{i+1}. #{doc}"
end

puts "\n2. Testing QueryBuilder execute_document_only_query..."
query_builder = JSONRecord::QueryBuilder.new(User)
puts "   Document conditions: #{query_builder.document_conditions}"
results = query_builder.send(:execute_document_only_query)
puts "   QueryBuilder returned: #{results.count} results"
results.each_with_index do |result, i|
  puts "   #{i+1}. #{result.class}: #{result.inspect}"
end

puts "\n3. Testing full User.all chain..."
all_users = User.all.to_a
puts "   User.all returned: #{all_users.count} users"

puts "\n🔧 Debug complete!"
