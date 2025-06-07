require './lib/JSONRecord'

class User < JSONRecord::Base
  column :name, String
  column :age, Integer
end

puts "🔧 Testing RocksDB direct operations..."

user = User.new(name: "Evan", age: 47)
user.save
puts "User saved with ID: #{user.id}"

# Test direct RocksDB operations
storage = User.document_storage
puts "Storage class: #{storage.class}"

# Test all_documents method directly
puts "\n🔧 Testing all_documents:"

begin
  # Try the private method directly for debugging
  all_docs = storage.send(:all_documents, 'users')
  puts "all_documents result: #{all_docs.inspect}"
rescue => e
  puts "all_documents error: #{e.message}"
end

# Test database iteration
puts "\n🔧 Testing database iteration:"

begin
  prefix = "doc:users:"
  found_keys = []
  storage.instance_variable_get(:@db_handle).each do |key, value|
    puts "Found key: #{key}"
    found_keys << key if key.start_with?(prefix)
  end
  puts "Found #{found_keys.size} keys with prefix '#{prefix}'"
rescue => e
  puts "Database iteration error: #{e.message}"
end

# Test specific document retrieval
puts "\n🔧 Testing specific retrieval:"
doc = storage.get_document('users', 1)
puts "Direct retrieval result: #{doc.inspect}"
