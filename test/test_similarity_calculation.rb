#!/usr/bin/env ruby

require_relative '../lib/JSONRecord'

class User < JSONRecord::Base
  column :name, String
  vector_field :profile_embedding, dimensions: 4
end

# Clean start
system("rm -rf data/jsonrecord*")

puts "🔧 TESTING VECTOR SIMILARITY CALCULATION 🔧"

# Create user with known vector
user = User.new(name: "TestUser")
user.profile_embedding = [1.0, 0.0, 0.0, 0.0]  # Simple vector
user.save

puts "1. Created user with vector [1.0, 0.0, 0.0, 0.0]"

# Test exact match
puts "\n2. Testing exact match search..."
exact_results = User.similar_to([1.0, 0.0, 0.0, 0.0], limit: 1)
puts "   Exact match results: #{exact_results.to_a.count} users"

# Test very similar vector  
puts "\n3. Testing similar vector search..."
similar_results = User.similar_to([0.9, 0.1, 0.0, 0.0], limit: 1)
puts "   Similar vector results: #{similar_results.to_a.count} users"

# Test orthogonal vector (should have low similarity)
puts "\n4. Testing orthogonal vector search..."
ortho_results = User.similar_to([0.0, 1.0, 0.0, 0.0], limit: 1)
puts "   Orthogonal vector results: #{ortho_results.to_a.count} users"

# Test with very low threshold
puts "\n5. Testing with threshold = -1.0 (should include everything)..."
all_results = User.similar_to([0.5, 0.5, 0.0, 0.0], limit: 1, threshold: -1.0)
puts "   Low threshold results: #{all_results.to_a.count} users"

puts "\n🔧 Test complete!"
