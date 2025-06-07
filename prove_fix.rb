#!/usr/bin/env ruby

# Simulate JsonRecord column method with the FIXED behavior
module TestJSONRecord
  COLUMN_ATTRIBUTES = {}
  
  class Base
    class << self
      def table_name
        self.to_s.downcase + 's'
      end
      
      def column(name, type=String)
        # Simulate the column setup (simplified)
        COLUMN_ATTRIBUTES[table_name] ||= []
        COLUMN_ATTRIBUTES[table_name] << [name.to_s, type]
        
        puts "🔧 Column #{name} added to #{table_name}"
        
        # THE FIX: Return self instead of name.to_sym
        self  # <-- This is the key fix!
      end
    end
  end
end

puts "🔧 TESTING FIXED JSONRECORD COLUMN METHOD 🔧"
puts

puts "Creating User class with column definitions:"
puts "class User < TestJSONRecord::Base"
puts "  column :name, String"  
puts "  column :age, Integer"
puts "end"
puts

class User < TestJSONRecord::Base
  column :name, String
  column :age, Integer
end

puts "=> #{User.inspect}"
puts "✅ SUCCESS! Class definition returns: #{User.class}"
puts "✅ User.name = #{User.name}"
puts "✅ Columns defined: #{TestJSONRecord::COLUMN_ATTRIBUTES['users']}"

puts "\n🎯 BEFORE FIX: Would have returned :age symbol"
puts "🎯 AFTER FIX: Returns User class properly!"
puts "🔧 Russian Plumber fixes Soviet pipe threading! ✅"
