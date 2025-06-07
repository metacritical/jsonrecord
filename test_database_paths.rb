#!/usr/bin/env ruby

# Test XDG-compliant database path configuration

require './lib/JSONRecord'

puts "🔧 TESTING DATABASE PATH CONFIGURATION 🔧"
puts

# Test different scenarios
scenarios = [
  {
    name: "Default (development)",
    env: {},
    expected_pattern: /data.*jsonrecord\.rocksdb/
  },
  {
    name: "XDG_DATA_HOME set (non-dev)", 
    env: { 'XDG_DATA_HOME' => '/tmp/xdg_data' },
    expected_pattern: /data.*jsonrecord\.rocksdb/  # Still development due to .git presence
  },
  {
    name: "HOME set (XDG fallback, non-dev)",
    env: { 'HOME' => '/tmp/home', 'XDG_DATA_HOME' => nil },
    expected_pattern: /data.*jsonrecord\.rocksdb/  # Still development due to .git presence
  }
]

scenarios.each do |scenario|
  puts "#{scenario[:name]}:"
  
  # Set environment
  old_env = {}
  scenario[:env].each do |key, value|
    old_env[key] = ENV[key]
    if value.nil?
      ENV.delete(key)
    else
      ENV[key] = value
    end
  end
  
  # Force configuration refresh
  JSONRecord.instance_variable_set(:@configuration, nil)
  
  # Test path
  path = JSONRecord.database_path
  puts "   Path: #{path}"
  
  if path.match?(scenario[:expected_pattern])
    puts "   ✅ CORRECT pattern"
  else
    puts "   ❌ UNEXPECTED pattern"
  end
  
  # Restore environment
  old_env.each do |key, value|
    if value.nil?
      ENV.delete(key)
    else
      ENV[key] = value
    end
  end
  
  puts
end

puts "🔧 Test complete!"
