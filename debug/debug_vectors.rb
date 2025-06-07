#!/usr/bin/env ruby

require_relative '../lib/JSONRecord'

puts "🔧 DEBUGGING VECTOR STORAGE 🔧"
puts

class User < JSONRecord::Base
  column :name, String
  vector_field :profile_embedding, dimensions: 4
end

# Clean start
system("rm -rf data/jsonrecord*")

puts "1. Creating user with vector..."
user = User.new(name: "TestUser")
puts "   Before setting vector: profile_embedding = #{user.profile_embedding}"

user.profile_embedding = [0.1, 0.2, 0.3, 0.4]
puts "   After setting vector: profile_embedding = #{user.profile_embedding}"

puts "\n2. Vector fields configuration..."
puts "   User.vector_fields = #{User.vector_fields}"
puts "   JSONRecord.vector_engine = #{JSONRecord.vector_engine}"

puts "\n3. Saving user..."
result = user.save
puts "   Save result: #{result ? 'SUCCESS' : 'FAILED'}"
puts "   User ID: #{user.id}"

puts "\n4. Checking vector storage..."
vector_storage = User.vector_storage
puts "   Vector storage engine: #{vector_storage.engine}"
puts "   Vector storage indexes: #{vector_storage.indexes}"

if vector_storage.respond_to?(:vector_storage)
  puts "   Internal vector storage: #{vector_storage.instance_variable_get(:@vector_storage)}"
end

puts "\n5. Testing similarity search..."
similar = User.similar_to([0.1, 0.2, 0.3, 0.4], limit: 1)
puts "   Similarity search result: #{similar.to_a.count} users"

puts "\n🔧 Debug complete!"
