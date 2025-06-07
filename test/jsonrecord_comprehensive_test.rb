require_relative 'test_helper'

describe JSONRecord do
  before do
    # Clean up any existing test data
    FileUtils.rm_rf(File.join(Dir.pwd, 'test_data'))
    FileUtils.rm_rf(File.join(Dir.pwd, 'data'))
    
    # Define test model
    @user_class = Class.new(JSONRecord::Base) do
      def self.name
        'User'
      end
      
      column :name, String
      column :email, String
      column :age, Integer
      column :skills, Array
      vector_field :profile_embedding, dimensions: 4
    end
    
    # Make it available as User constant for testing
    Object.const_set(:User, @user_class) unless defined?(User)
  end
  
  after do
    # Clean up test data
    FileUtils.rm_rf(File.join(Dir.pwd, 'test_data'))
    FileUtils.rm_rf(File.join(Dir.pwd, 'data'))
    
    # Remove test constant
    Object.send(:remove_const, :User) if defined?(User)
  end
  
  describe "Version" do
    it "should have a version number" do
      _(JSONRecord::VERSION).wont_be_nil
    end
  end
  
  describe "Storage Adapters" do
    it "should use storage adapter (RocksDB or FileAdapter fallback)" do
      storage = User.document_storage
      _(storage).must_respond_to :put_document
      _(storage).must_respond_to :get_document
      _(storage).must_respond_to :find_documents
      
      # Should be either RocksDB or FileAdapter
      adapter_name = storage.class.name
      _(adapter_name).must_match(/RocksDBAdapter|FileAdapter/)
    end
    
    it "should have vector storage" do
      vector_storage = User.vector_storage
      _(vector_storage).must_respond_to :add_vector
      _(vector_storage).must_respond_to :search_similar
    end
  end
  
  describe "Model Definition" do
    it "should define columns correctly" do
      column_names = User.column_names
      _(column_names).must_include 'name'
      _(column_names).must_include 'email'
      _(column_names).must_include 'age'
      _(column_names).must_include 'skills'
    end
    
    it "should have table name" do
      _(User.table_name).must_equal 'users'
    end
    
    it "should define vector fields" do
      vector_fields = User.vector_fields
      _(vector_fields).must_include :profile_embedding
      _(vector_fields[:profile_embedding][:dimensions]).must_equal 4
    end
  end
  
  describe "CRUD Operations" do
    it "should create and save new records" do
      user = User.new(name: "Evan", email: "evan@test.com", age: 47)
      result = user.save
      
      _(result).wont_be_nil
      _(user.id).wont_be_nil
      _(user.id).must_be :>, 0
    end
    
    it "should find saved records" do
      user = User.new(name: "Boris", email: "boris@test.com", age: 45)
      user.save
      
      found_user = User.find(user.id)
      _(found_user.name).must_equal "Boris"
      _(found_user.email).must_equal "boris@test.com"
      _(found_user.age).must_equal 45
    end
    
    it "should update existing records" do
      user = User.new(name: "Dmitri", age: 35)
      user.save
      
      user.age = 36
      user.save
      
      updated_user = User.find(user.id)
      _(updated_user.age).must_equal 36
    end
    
    it "should delete records" do
      user = User.new(name: "TestUser", age: 25)
      user.save
      user_id = user.id
      
      user.destroy
      
      _(proc { User.find(user_id) }).must_raise JSONRecord::RecordNotFound
    end
    
    it "should handle new_record? and persisted? states" do
      user = User.new(name: "StateTest", age: 30)
      _(user.new_record?).must_equal true
      _(user.persisted?).must_equal false
      
      user.save
      _(user.new_record?).must_equal false
      _(user.persisted?).must_equal true
    end
  end
  
  describe "Query Operations" do
    before do
      # Create test data
      @users = [
        User.new(name: "Alice", age: 25, skills: ["ruby", "python"]),
        User.new(name: "Bob", age: 35, skills: ["javascript", "react"]),
        User.new(name: "Charlie", age: 45, skills: ["ruby", "rails"]),
        User.new(name: "Diana", age: 28, skills: ["python", "django"])
      ]
      @users.each(&:save)
    end
    
    it "should find all records" do
      all_users = User.all.to_a
      _(all_users.length).must_equal 4
    end
    
    it "should count records" do
      _(User.count).must_equal 4
    end
    
    it "should find first and last records" do
      first_user = User.first
      last_user = User.last
      
      _(first_user).wont_be_nil
      _(last_user).wont_be_nil
      _(first_user.id).wont_equal last_user.id
    end
    
    it "should check if records exist" do
      _(User.exists?).must_equal true
      _(User.exists?(name: "Alice")).must_equal true
      _(User.exists?(name: "NonExistent")).must_equal false
    end
    
    it "should perform simple where queries" do
      alice_users = User.where(name: "Alice").to_a
      _(alice_users.length).must_equal 1
      _(alice_users.first.name).must_equal "Alice"
    end
    
    it "should perform range queries" do
      older_users = User.where(age: { gte: 35 }).to_a
      _(older_users.length).must_equal 2
      older_users.each { |user| _(user.age).must_be :>=, 35 }
      
      younger_users = User.where(age: { lt: 30 }).to_a
      _(younger_users.length).must_equal 2
      younger_users.each { |user| _(user.age).must_be :<, 30 }
    end
    
    it "should perform array includes queries" do
      ruby_users = User.where(skills: { includes: "ruby" }).to_a
      _(ruby_users.length).must_equal 2
      
      ruby_user_names = ruby_users.map(&:name).sort
      _(ruby_user_names).must_equal ["Alice", "Charlie"]
    end
    
    it "should limit and offset results" do
      limited_users = User.limit(2).to_a
      _(limited_users.length).must_equal 2
      
      offset_users = User.offset(1).limit(2).to_a
      _(offset_users.length).must_equal 2
    end
  end
  
  describe "Vector Similarity" do
    before do
      @user1 = User.new(name: "VectorUser1", age: 30)
      @user1.profile_embedding = [0.8, 0.2, 0.1, 0.1]
      @user1.save
      
      @user2 = User.new(name: "VectorUser2", age: 32)
      @user2.profile_embedding = [0.7, 0.3, 0.1, 0.2]
      @user2.save
      
      @user3 = User.new(name: "VectorUser3", age: 28)
      @user3.profile_embedding = [0.1, 0.1, 0.8, 0.7]
      @user3.save
    end
    
    it "should store and retrieve vector embeddings" do
      _(@user1.profile_embedding).must_equal [0.8, 0.2, 0.1, 0.1]
      _(@user2.profile_embedding).must_equal [0.7, 0.3, 0.1, 0.2]
    end
    
    it "should perform vector similarity search" do
      # Query vector similar to user1 and user2
      query_vector = [0.75, 0.25, 0.1, 0.15]
      
      similar_users = User.similar_to(query_vector, limit: 2).to_a
      _(similar_users.length).must_be :<=, 2
      
      # Results should be ordered by similarity
      if similar_users.length > 1
        first_similarity = similar_users[0].similarity_score || 0
        second_similarity = similar_users[1].similarity_score || 0
        _(first_similarity).must_be :>=, second_similarity
      end
    end
  end
  
  describe "Performance Benchmarks" do
    it "should handle bulk operations efficiently" do
      start_time = Time.now
      
      # Create 100 test records
      100.times do |i|
        user = User.new(
          name: "BulkUser#{i}",
          email: "bulk#{i}@test.com",
          age: 20 + (i % 50),
          skills: ["skill#{i % 3}"]
        )
        user.save
      end
      
      creation_time = Time.now - start_time
      _(creation_time).must_be :<, 5.0  # Should complete in under 5 seconds
      
      # Query performance test
      start_time = Time.now
      results = User.where(age: { gte: 40 }).to_a
      query_time = Time.now - start_time
      
      _(query_time).must_be :<, 1.0  # Queries should be fast
      _(results.length).must_be :>, 0  # Should find some results
    end
  end
  
  describe "Error Handling" do
    it "should raise RecordNotFound for missing records" do
      _(proc { User.find(99999) }).must_raise JSONRecord::RecordNotFound
    end
    
    it "should handle invalid data gracefully" do
      # This should not crash the system
      user = User.new(name: nil, age: "invalid")
      result = user.save
      
      # Save might fail, but shouldn't crash
      # Exact behavior depends on validation implementation
    end
  end
  
  describe "Storage Backend Compatibility" do
    it "should work with both RocksDB and FileAdapter" do
      # Test that both storage backends provide consistent interface
      storage = User.document_storage
      
      # Test document operations
      test_doc = { "id" => 999, "name" => "BackendTest", "age" => 30 }
      
      # Store document
      storage.put_document("test_table", 999, test_doc)
      
      # Retrieve document
      retrieved_doc = storage.get_document("test_table", 999)
      _(retrieved_doc["name"]).must_equal "BackendTest"
      _(retrieved_doc["age"]).must_equal 30
      
      # Find documents
      all_docs = storage.find_documents("test_table")
      _(all_docs).must_include retrieved_doc
      
      # Clean up
      storage.delete_document("test_table", 999)
    end
  end
end
