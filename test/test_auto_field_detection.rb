#!/usr/bin/env ruby

require_relative '../lib/JSONRecord'

puts "🔧 TESTING AUTO-FIELD DETECTION 🔧"
puts

# Clean start
system("rm -rf data/jsonrecord*")

puts "1. Testing single vector field auto-detection..."

class User < JSONRecord::Base
  column :name, String
  vector_field :profile_embedding, dimensions: 4
end

user1 = User.new(name: "TechUser")
user1.profile_embedding = [0.8, 0.2, 0.1, 0.1]
user1.save

user2 = User.new(name: "ArtUser")
user2.profile_embedding = [0.1, 0.1, 0.8, 0.7]
user2.save

# Test auto-detection (no field: parameter)
tech_query = [0.9, 0.1, 0.0, 0.0]
similar_users = User.similar_to(tech_query, limit: 2).to_a

puts "   ✅ Auto-detection with single field: #{similar_users.count} users found"
similar_users.each do |user|
  score = user.similarity_score || 0
  puts "   - #{user.name}: similarity = #{score.round(3)}"
end

puts "\n2. Testing multiple vector fields..."

class Product < JSONRecord::Base
  column :name, String
  vector_field :description_embedding, dimensions: 4
  vector_field :image_features, dimensions: 4
end

product = Product.new(name: "TestProduct")
product.description_embedding = [0.5, 0.5, 0.5, 0.5]
product.image_features = [0.2, 0.2, 0.8, 0.8]
product.save

puts "   Testing multiple fields error handling..."
begin
  # This should fail and require field: parameter
  Product.similar_to([0.6, 0.4, 0.3, 0.7]).to_a
  puts "   ❌ Should have failed but didn't"
rescue ArgumentError => e
  puts "   ✅ Correctly detected multiple fields: #{e.message}"
end

puts "\n3. Testing explicit field specification still works..."
explicit_results = Product.similar_to([0.6, 0.4, 0.3, 0.7], field: :description_embedding).to_a
puts "   ✅ Explicit field specification: #{explicit_results.count} products found"

puts "\n🔧 Auto-field detection test complete!"
