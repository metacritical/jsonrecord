#!/usr/bin/env ruby

require_relative '../lib/JSONRecord'

puts "🔧 TESTING ANNOY ENGINE FIX 🔧"
puts

# Clean start
system("rm -rf data/jsonrecord*")
JSONRecord.vector_engine = :annoy

class User < JSONRecord::Base
  column :name, String
  vector_field :profile_embedding, dimensions: 4
end

puts "1. Testing Annoy engine setup..."

begin
  user1 = User.new(name: "TechUser")
  user1.profile_embedding = [0.8, 0.2, 0.1, 0.1]
  user1.save
  puts "   ✅ First user saved successfully"

  user2 = User.new(name: "ArtUser") 
  user2.profile_embedding = [0.1, 0.1, 0.8, 0.7]
  user2.save
  puts "   ✅ Second user saved successfully"

  puts "   📊 Testing search..."
  tech_query = [0.9, 0.1, 0.0, 0.0]
  similar_users = User.similar_to(tech_query, limit: 2).to_a
  
  puts "   Results: #{similar_users.count} users found"
  similar_users.each do |user|
    score = user.similarity_score || 0
    puts "     - #{user.name}: #{score.round(3)}"
  end
  
  if similar_users.count > 0
    puts "\n🎉 ANNOY ENGINE WORKING!"
  else
    puts "\n❌ No results - search may need index build"
  end

rescue => e
  puts "   ❌ Error: #{e.message}"
  puts "   Backtrace: #{e.backtrace.first(3).join("\n              ")}"
end
