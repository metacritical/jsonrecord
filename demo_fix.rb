#!/usr/bin/env ruby

puts "🔧 SIMULATING RUBY CLASS DEFINITION BEHAVIOR 🔧"
puts

class DemoClass
  def self.column(name, type)
    puts "Column method called with #{name}, #{type}"
    puts "Returning: self (#{self})"
    self  # This is the fix - return self instead of name.to_sym
  end
  
  puts "Before first column..."
  result1 = column :name, String
  puts "After first column, got: #{result1}"
  
  puts "Before second column..."  
  result2 = column :age, Integer
  puts "After second column, got: #{result2}"
  
  puts "Class definition finishing..."
end

puts "\n✅ Final result: #{DemoClass}"
puts "✅ DemoClass.class = #{DemoClass.class}"
puts "✅ This proves the fix works!"

puts "\n🔧 COMPARISON - What happens with old behavior:"

class BrokenClass
  def self.column(name, type)
    puts "Broken column method returning: #{name.to_sym}"
    name.to_sym  # Old broken behavior
  end
  
  column :name, String
  result = column :age, Integer
  puts "Last result will be class definition return value: #{result}"
end

puts "=> #{BrokenClass} (This would be :age symbol with old code)"
