#!/usr/bin/env ruby

require_relative '../lib/JSONRecord'

puts "🔧 DEBUGGING TABLE FILTERING 🔧"
puts

class User < JSONRecord::Base
  column :name, String
end

class Product < JSONRecord::Base
  column :title, String
end

# Clean start
system("rm -rf data/jsonrecord*")

# Force fresh storage
JSONRecord::Base.class_variable_set(:@@document_storage, nil) if JSONRecord::Base.class_variable_defined?(:@@document_storage)

puts "1. Creating test records..."
user1 = User.new(name: "TestUser1")
user1.save
puts "   User1 saved: #{user1['_table']}"

product1 = Product.new(title: "TestProduct1")  
product1.save
puts "   Product1 saved: #{product1['_table']}"

puts "\n2. Direct storage inspection..."
storage = User.document_storage
puts "   Storage class: #{storage.class}"

puts "\n3. Raw database contents:"
count = 0
storage.db_handle.each do |key, value|
  count += 1
  begin
    doc = MessagePack.unpack(key)
    puts "   #{count}. ID=#{doc['id']}, _table=#{doc['_table']}, name/title=#{doc['name'] || doc['title']}"
  rescue
    puts "   #{count}. Non-document key"
  end
  break if count >= 10
end

puts "\n4. Testing User.all..."
user_docs = User.document_storage.send(:all_documents, "users")
puts "   all_documents('users') returned: #{user_docs.count} documents"
user_docs.each { |doc| puts "     - #{doc['name']} (_table=#{doc['_table']})" }

puts "\n5. Testing User.all through query builder..."
all_users = User.all.to_a
puts "   User.all returned: #{all_users.count} users"

puts "\n🔧 Debug complete!"
