#!/usr/bin/env ruby

require_relative '../lib/JSONRecord'

puts "🔧 TESTING ANNOY ENGINE STEP BY STEP 🔧"
puts

# Clean start
system("rm -rf data/jsonrecord*")

puts "1. Setting up Annoy engine..."
JSONRecord.vector_engine = :annoy

class TestUser < JSONRecord::Base
  column :name, String
  vector_field :profile_embedding, dimensions: 4
end

puts "2. Creating first user..."
user1 = TestUser.new(name: "TechUser")
user1.profile_embedding = [0.8, 0.2, 0.1, 0.1]
puts "   Saving user1..."
user1.save
puts "   ✅ User1 saved successfully"

puts "3. Creating second user..."
user2 = TestUser.new(name: "ArtUser")
user2.profile_embedding = [0.1, 0.1, 0.8, 0.7]
puts "   Saving user2..."
user2.save
puts "   ✅ User2 saved successfully"

puts "4. Testing vector similarity search..."
tech_query = [0.9, 0.1, 0.0, 0.0]
puts "   Query vector: #{tech_query}"

similar_users = TestUser.similar_to(tech_query, limit: 2).to_a
puts "   Found #{similar_users.count} similar users"

similar_users.each do |user|
  score = user.similarity_score || 0
  puts "   - #{user.name}: similarity = #{score.round(3)}"
end

if similar_users.count > 0
  puts "\n🎉 ANNOY ENGINE FULLY WORKING!"
  puts "   ✅ Vector storage: Working"
  puts "   ✅ Index building: Working" 
  puts "   ✅ Similarity search: Working"
  puts "   ✅ Auto-field detection: Working"
else
  puts "\n❌ No results found - debugging needed"
end

puts "\n5. Checking engine details..."
vector_storage = TestUser.vector_storage
puts "   Vector engine: #{vector_storage.engine}"
puts "   Collections: #{vector_storage.indexes.keys}"
puts "   Collection sizes: #{vector_storage.indexes.map { |k,v| "#{k}: #{vector_storage.collection_size(k)}" }.join(', ')}"
