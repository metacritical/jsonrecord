#!/usr/bin/env ruby

# CRITICAL RocksDB Parameter Order Verification Test
# Based on discovery from context: RocksDB Ruby gem has SWAPPED PARAMETERS!

require 'rocksdb'
require 'fileutils'

puts "🔧 VERIFYING ROCKSDB PARAMETER ORDER BUG 🔧"
puts

# Clean database
test_db_path = "/tmp/test_rocksdb_order"
FileUtils.rm_rf(test_db_path)

begin
  db = RocksDB.open(test_db_path)
  
  puts "Testing RocksDB parameter order..."
  
  # Test 1: Standard assumption - put(key, value)
  puts "\n1. Testing standard put(key, value) assumption:"
  db.put("test_key_1", "test_value_1")
  db.put("test_key_2", "test_value_2")
  
  # Verify what's actually stored as keys
  puts "\n2. Iterating through actual keys stored:"
  keys_found = []
  db.each do |key, value|
    keys_found << key
    puts "  Key found: '#{key}' → Value: '#{value}'"
  end
  
  # Test 3: What does get() return?
  puts "\n3. Testing retrieval with get():"
  result1 = db.get("test_key_1")
  result2 = db.get("test_value_1")  # Try reverse
  puts "  get('test_key_1') = '#{result1}'"
  puts "  get('test_value_1') = '#{result2}'"
  
  # DISCOVERY ANALYSIS
  puts "\n🚨 ANALYSIS:"
  if keys_found.include?("test_value_1") && keys_found.include?("test_value_2")
    puts "✅ CONFIRMED: RocksDB Ruby gem has SWAPPED PARAMETERS!"
    puts "   - VALUES are being stored as KEYS"
    puts "   - Must use put(value, key) instead of put(key, value)"
  elsif keys_found.include?("test_key_1") && keys_found.include?("test_key_2") 
    puts "❌ UNEXPECTED: Parameters seem normal"
    puts "   - Keys are stored as keys (expected behavior)"
  else
    puts "❓ UNCLEAR: Unexpected key pattern found"
  end
  
  db.close
rescue => e
  puts "ERROR: #{e.message}"
ensure
  FileUtils.rm_rf(test_db_path)
end

puts "\n🔧 Test complete!"
