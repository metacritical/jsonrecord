#!/usr/bin/env ruby

require_relative '../lib/JSONRecord'

class User < JSONRecord::Base
  column :name, String
end

class Product < JSONRecord::Base  
  column :title, String
end

puts "Creating test records..."
user = User.new(name: 'TableTest')
user.save
puts "User: #{user.to_h.inspect}"

product = Product.new(title: 'TestProduct')
product.save 
puts "Product: #{product.to_h.inspect}"

puts "\nTesting User.all vs Product.all..."
puts "User.all count: #{User.all.to_a.count}"
puts "Product.all count: #{Product.all.to_a.count}"
puts "User table name: #{User.table_name}"
puts "Product table name: #{Product.table_name}"
