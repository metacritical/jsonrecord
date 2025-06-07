#!/usr/bin/env ruby

# Debug QueryBuilder.to_a method step by step

require_relative '../lib/JSONRecord'

puts "🔧 DEBUGGING QUERYBUILDER.TO_A STEP BY STEP 🔧"
puts

class User < JSONRecord::Base
  column :name, String
  column :age, Integer
end

puts "1. Creating QueryBuilder..."
query_builder = JSONRecord::QueryBuilder.new(User)
puts "   limit_value: #{query_builder.limit_value.inspect}"
puts "   offset_value: #{query_builder.offset_value.inspect}"
puts "   order_conditions: #{query_builder.order_conditions.inspect}"

puts "\n2. Executing execute_query..."
results = query_builder.send(:execute_query)
puts "   execute_query returned: #{results.count} results"
results.each_with_index do |result, i|
  puts "   #{i+1}. #{result.class}"
end

puts "\n3. Applying ordering..."
query_builder.send(:apply_ordering, results)
puts "   After apply_ordering: #{results.count} results"

puts "\n4. Applying limit/offset..."
puts "   Before limit/offset: #{results.count} results"
puts "   offset_value: #{query_builder.offset_value}"
puts "   limit_value: #{query_builder.limit_value}"

start_index = query_builder.offset_value
end_index = query_builder.limit_value ? start_index + query_builder.limit_value : results.size
puts "   Calculated start_index: #{start_index}"
puts "   Calculated end_index: #{end_index}"
puts "   Array slice [#{start_index}...#{end_index}]"

final_results = query_builder.send(:apply_limit_offset, results)
puts "   After apply_limit_offset: #{final_results.count} results"

puts "\n5. Full to_a method..."
to_a_results = query_builder.to_a
puts "   Full to_a returned: #{to_a_results.count} results"

puts "\n🔧 Debug complete!"
