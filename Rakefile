require "bundler/gem_tasks"
require "rake/testtask"


Rake::TestTask.new do |task|
  task.libs << "lib/JSONRecord"
  task.test_files = FileList['test/lib/jsonrecord/*_test.rb']
  task.verbose = true
end		

task :default => :test
