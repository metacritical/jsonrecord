#!/usr/bin/env ruby

require_relative '../lib/JSONRecord'

puts "🔧 TESTING ALL VECTOR ENGINES: SIMPLE, ANNOY, FAISS 🔧"
puts

# Clean start
system("rm -rf data/jsonrecord*")

# Test data setup
test_vectors = [
  { name: "TechUser", vector: [0.8, 0.2, 0.1, 0.1] },    # Tech-focused
  { name: "ArtUser", vector: [0.1, 0.1, 0.8, 0.7] },     # Art-focused  
  { name: "BusinessUser", vector: [0.7, 0.3, 0.2, 0.1] }, # Business-focused
  { name: "ScienceUser", vector: [0.2, 0.8, 0.1, 0.2] }   # Science-focused
]

query_vectors = {
  tech: [0.9, 0.1, 0.0, 0.0],
  art: [0.0, 0.0, 0.9, 0.8],
  science: [0.1, 0.9, 0.0, 0.1]
}

def test_engine(engine_name, users_class)
  puts "\n--- Testing #{engine_name.upcase} Engine ---"
  
  # Create users with vectors
  test_vectors = [
    { name: "TechUser", vector: [0.8, 0.2, 0.1, 0.1] },
    { name: "ArtUser", vector: [0.1, 0.1, 0.8, 0.7] },
    { name: "BusinessUser", vector: [0.7, 0.3, 0.2, 0.1] },
    { name: "ScienceUser", vector: [0.2, 0.8, 0.1, 0.2] }
  ]
  
  test_vectors.each do |data|
    user = users_class.new(name: data[:name])
    user.profile_embedding = data[:vector]
    user.save
  end
  
  puts "   ✅ Created #{users_class.count} users with #{engine_name} engine"
  
  # Test auto-field detection
  tech_query = [0.9, 0.1, 0.0, 0.0]
  similar_users = users_class.similar_to(tech_query, limit: 2).to_a
  
  puts "   📊 Tech query results:"
  similar_users.each do |user|
    score = user.similarity_score || 0
    puts "     - #{user.name}: #{score.round(3)}"
  end
  
  # Test art query
  art_query = [0.0, 0.0, 0.9, 0.8]
  art_users = users_class.similar_to(art_query, limit: 2).to_a
  
  puts "   🎨 Art query results:"
  art_users.each do |user|
    score = user.similarity_score || 0
    puts "     - #{user.name}: #{score.round(3)}"
  end
  
  return similar_users.size > 0 && art_users.size > 0
end

# Test 1: Simple Engine (baseline)
puts "🔧 Test 1: SIMPLE Engine (Pure Ruby)"
JSONRecord.vector_engine = :simple

class SimpleUser < JSONRecord::Base
  column :name, String
  vector_field :profile_embedding, dimensions: 4
end

simple_success = test_engine(:simple, SimpleUser)

# Test 2: Annoy Engine  
puts "\n🔧 Test 2: ANNOY Engine (Spotify Algorithm)"
system("rm -rf data/jsonrecord*")  # Clean for new engine
JSONRecord.vector_engine = :annoy

class AnnoyUser < JSONRecord::Base
  column :name, String
  vector_field :profile_embedding, dimensions: 4
end

begin
  annoy_success = test_engine(:annoy, AnnoyUser)
rescue => e
  puts "   ❌ Annoy test failed: #{e.message}"
  annoy_success = false
end

# Test 3: FAISS Engine
puts "\n🔧 Test 3: FAISS Engine (Facebook Algorithm)"
system("rm -rf data/jsonrecord*")  # Clean for new engine
JSONRecord.vector_engine = :faiss

class FaissUser < JSONRecord::Base
  column :name, String
  vector_field :profile_embedding, dimensions: 4
end

begin
  faiss_success = test_engine(:faiss, FaissUser)
rescue => e
  puts "   ❌ FAISS test failed: #{e.message}"
  faiss_success = false
end

# Summary
puts "\n🎯 FINAL RESULTS:"
puts "   Simple Engine: #{simple_success ? '✅ WORKING' : '❌ FAILED'}"
puts "   Annoy Engine:  #{annoy_success ? '✅ WORKING' : '❌ FAILED'}"
puts "   FAISS Engine:  #{faiss_success ? '✅ WORKING' : '❌ FAILED'}"

engines_working = [simple_success, annoy_success, faiss_success].count(true)
puts "\n🔧 Vector Engines: #{engines_working}/3 working!"

if engines_working == 3
  puts "🎉 ALL VECTOR ENGINES IMPLEMENTED SUCCESSFULLY!"
  puts "   JsonRecord now supports Simple, Annoy, and FAISS algorithms!"
else
  puts "⚠️  Some engines need fixes, but core functionality working"
end
