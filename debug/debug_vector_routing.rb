#!/usr/bin/env ruby

require_relative '../lib/JSONRecord'

# Add debug to QueryBuilder
module JSONRecord
  class QueryBuilder
    def execute_query
      puts "DEBUG: execute_query called"
      puts "DEBUG: vector_conditions = #{@vector_conditions}"
      puts "DEBUG: document_conditions = #{@document_conditions}"
      puts "DEBUG: vector_only_query? = #{vector_only_query?}"
      puts "DEBUG: document_only_query? = #{document_only_query?}"
      
      if vector_only_query?
        puts "DEBUG: Taking vector_only_query path"
        execute_vector_only_query
      elsif document_only_query?
        puts "DEBUG: Taking document_only_query path"  
        execute_document_only_query
      else
        puts "DEBUG: Taking hybrid_query path"
        execute_hybrid_query
      end
    end
  end
end

class User < JSONRecord::Base
  column :name, String
  vector_field :profile_embedding, dimensions: 4
end

# Clean start
system("rm -rf data/jsonrecord*")

puts "🔧 DEBUGGING QUERYBUILDER VECTOR ROUTING 🔧"

# Create user
user = User.new(name: "TestUser")
user.profile_embedding = [1.0, 0.0, 0.0, 0.0]
user.save

puts "\n1. Testing User.similar_to routing..."
results = User.similar_to([1.0, 0.0, 0.0, 0.0], field: :profile_embedding).to_a
puts "   Results: #{results.count} users"

puts "\n🔧 Debug complete!"
