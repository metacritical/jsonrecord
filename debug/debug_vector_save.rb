#!/usr/bin/env ruby

require_relative '../lib/JSONRecord'

# Add debug to save_vectors method
module JSONRecord
  class Base
    def save_vectors
      puts "DEBUG: save_vectors called"
      puts "DEBUG: vector_fields = #{self.class.vector_fields}"
      
      self.class.vector_fields.each do |field_name, config|
        puts "DEBUG: Processing field #{field_name}"
        vector = send(field_name)
        puts "DEBUG: Vector for #{field_name} = #{vector}"
        
        next unless vector
        
        collection_name = "#{self.class.table_name}_#{field_name}"
        puts "DEBUG: Adding to collection #{collection_name}"
        
        self.class.vector_storage.add_vector(
          collection_name,
          self["id"],
          vector,
          { updated_at: Time.now.utc.iso8601 }
        )
        
        puts "DEBUG: Vector added successfully"
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

puts "🔧 DEBUGGING VECTOR SAVE WITH DEBUG OUTPUT 🔧"

user = User.new(name: "DebugUser")
user.profile_embedding = [0.1, 0.2, 0.3, 0.4]

puts "Before save:"
puts "  has_vector_fields? = #{user.send(:has_vector_fields?)}"
puts "  profile_embedding = #{user.profile_embedding}"

puts "\nCalling save..."
user.save

puts "\nAfter save:"
vector_storage = User.vector_storage
puts "  Vector storage indexes: #{vector_storage.indexes}"
puts "  Vector storage engine: #{vector_storage.engine}"

# Check the actual simple storage
internal = vector_storage.instance_variable_get(:@vector_storage)
puts "  Internal vector storage: #{internal}"

puts "\nTesting similarity search now..."
similar = User.similar_to([0.1, 0.2, 0.3, 0.4], limit: 1)
puts "  Similarity search result: #{similar.to_a}"
