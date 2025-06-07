#!/usr/bin/env ruby

puts "🔧 RUSSIAN PLUMBER TEST SUITE 🔧"
puts "Running comprehensive JSONRecord tests..."
puts

# Set test environment
ENV['JSONRECORD_ENV'] = 'test'

require 'minitest/autorun'
require 'minitest/reporters'

# Use progress reporter for better output
Minitest::Reporters.use! Minitest::Reporters::ProgressReporter.new

# Load all test files
test_files = Dir[File.join(__dir__, '..', 'test', '**', '*_test.rb')]

if test_files.empty?
  puts "❌ No test files found!"
  exit 1
end

puts "📁 Loading test files:"
test_files.each do |file|
  puts "  - #{File.basename(file)}"
  require_relative file
end

puts "\n🚀 Starting test execution..."
