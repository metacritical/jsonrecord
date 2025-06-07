#!/usr/bin/env ruby

require_relative '../lib/JSONRecord'

puts "🔧 TESTING CURRENT VECTOR CAPABILITIES 🔧"
puts

class User < JSONRecord::Base
  column :name, String
  column :age, Integer
  vector_field :profile_embedding, dimensions: 4
end

# Clean start
system("rm -rf data/jsonrecord*")

# Create users with vector embeddings
puts "1. Creating users with vector embeddings..."
user1 = User.new(name: "TechUser", age: 30)
user1.profile_embedding = [0.8, 0.2, 0.1, 0.1]  # Tech-focused
user1.save

user2 = User.new(name: "ArtUser", age: 28)
user2.profile_embedding = [0.1, 0.1, 0.8, 0.7]  # Art-focused
user2.save

user3 = User.new(name: "BusinessUser", age: 35)
user3.profile_embedding = [0.7, 0.3, 0.2, 0.1]  # Business-focused
user3.save

puts "   Created #{User.count} users with embeddings"

puts "\n2. Testing vector similarity search..."
# Query for tech-oriented users
tech_query = [0.9, 0.1, 0.0, 0.0]
similar_users = User.similar_to(tech_query, field: :profile_embedding, limit: 2).to_a

puts "   Tech query [0.9, 0.1, 0.0, 0.0] found #{similar_users.count} similar users:"
similar_users.each do |user|
  score = user.similarity_score || 0
  puts "   - #{user.name}: similarity = #{score.round(3)}"
end

puts "\n3. Testing art query..."
art_query = [0.0, 0.0, 0.9, 0.8]
art_users = User.similar_to(art_query, field: :profile_embedding, limit: 2).to_a

puts "   Art query [0.0, 0.0, 0.9, 0.8] found #{art_users.count} similar users:"
art_users.each do |user|
  score = user.similarity_score || 0
  puts "   - #{user.name}: similarity = #{score.round(3)}"
end

puts "\n4. Checking vector engine..."
vector_storage = User.vector_storage
puts "   Vector engine: #{vector_storage.engine}"
puts "   Collections: #{vector_storage.indexes.keys}"

puts "\n🔧 Test complete!"
