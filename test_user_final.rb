require './lib/JSONRecord'
class User < JSONRecord::Base
  column :name, String
  column :age, Integer
end
puts "Storage: #{User.document_storage.class}"  # Should show FileAdapter
user = User.new(name: "Evan", age: 47)
user.save
puts "User saved with ID: #{user.id}"
# Test new query features
users = User.where(age: { gte: 40 }).to_a
puts "Users 40+: #{users.size}"
