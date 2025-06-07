![JSONRECORD](misc/icon_jsonrecord.JPG)

# JSONRecord

🔧 **High-Performance Document Database for Ruby** 🔧

JSONRecord is a modern, fast document storage library with an ActiveRecord-style interface. Built on **RocksDB + FAISS** for optimal performance, it provides seamless Rails integration and powerful vector similarity search capabilities.

## ⚡ Performance Features

- **🚀 RocksDB Backend**: Lightning-fast binary storage with MessagePack serialization
- **🔍 Vector Search**: Built-in FAISS integration for semantic similarity queries  
- **📊 Efficient Indexing**: Automatic secondary indexes for fast range queries
- **⚖️ Smart Storage**: Automatic Rails detection with XDG-compliant paths

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'JSONRecord'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install JSONRecord
```

## Quick Start

### Basic Model Definition

```ruby
class User < JSONRecord::Base
  column :name, String
  column :email, String
  column :age, Integer
  column :skills, Array
  
  # Vector field for semantic search
  vector_field :profile_embedding, dimensions: 384
end
```

### CRUD Operations

```ruby
# Create
user = User.new(name: "Alice", email: "alice@example.com", age: 28)
user.save
# => {"name"=>"Alice", "email"=>"alice@example.com", "age"=>28, "id"=>1, ...}

# Read
user = User.find(1)
alice = User.find_by_name("Alice")
all_users = User.all

# Update  
user.age = 29
user.save

# Delete
user.destroy
```

### Advanced Queries

```ruby
# Range queries
young_users = User.where(age: { lt: 30 }).to_a
seniors = User.where(age: { gte: 65 }).to_a

# Array inclusion
ruby_devs = User.where(skills: { includes: "ruby" }).to_a

# Chaining with limits
top_users = User.where(age: { gte: 25 }).limit(10).offset(5).to_a

# Counting and existence
User.count
User.exists?(email: "alice@example.com")
```

### Vector Similarity Search

```ruby
# Add vector embedding
user.profile_embedding = [0.1, 0.2, 0.3, ...]  # From your ML model
user.save

# Semantic similarity search
query_vector = [0.15, 0.25, 0.35, ...]
similar_users = User.similar_to(query_vector, limit: 5).to_a

# Access similarity scores
similar_users.each do |user|
  puts "#{user.name}: #{user.similarity_score}"
end
```

## 🔧 Configuration

### Rails Applications

JSONRecord automatically stores data in `db/jsonrecord.rocksdb` (like SQLite).

```ruby
# config/initializers/jsonrecord.rb
JSONRecord.configure do |config|
  config.database_path = Rails.root.join('storage', 'jsonrecord.rocksdb')
  config.vector_engine = :faiss
  config.enable_compression = true
end
```

### Standalone Applications

Follows XDG Base Directory specification:

- **`$XDG_DATA_HOME/jsonrecord/`** (if set)
- **`~/.local/share/jsonrecord/`** (standard fallback)
- **`./data/jsonrecord.rocksdb`** (development, git-ignored)

### Custom Configuration

```ruby
JSONRecord.configure do |config|
  config.database_path = '/var/lib/myapp/database.rocksdb'
  config.vector_engine = :faiss  # or :simple, :annoy
  config.rocksdb_options = {
    write_buffer_size: 64.megabytes,
    max_open_files: 1000,
    compression: 'snappy'
  }
end
```

See [Configuration Guide](docs/CONFIGURATION.md) for detailed examples.

## 🏗️ Rails Integration

JSONRecord works seamlessly with Rails:

```ruby
# Gemfile
gem 'JSONRecord'

# Generate model
$ rails generate jsonrecord:model Article

# app/models/article.rb
class Article < JSONRecord::Base
  column :title, String
  column :content, String
  column :tags, Array
  column :published_at, Time
  
  vector_field :content_embedding, dimensions: 768
end

# Use in controllers
class ArticlesController < ApplicationController
  def index
    @articles = Article.where(published_at: { gte: 1.week.ago })
  end
  
  def search
    # Semantic search with user query
    embedding = generate_embedding(params[:query])
    @articles = Article.similar_to(embedding, limit: 10)
  end
end
```

## 📊 Performance

JSONRecord delivers **enterprise-grade performance**:

- **🚀 10-100x faster** than JSON file storage
- **📈 Horizontal scaling** with RocksDB's proven architecture  
- **🔍 Sub-millisecond queries** with automatic indexing
- **💾 Efficient storage** with MessagePack compression

## 🧪 Testing

Run the comprehensive test suite:

```bash
$ bundle exec ruby run_tests.rb
```

## 🛠️ Development

After checking out the repo, run:

```bash
$ bundle install
$ ruby test_isolated_all.rb  # Quick functionality test
```

## 🤝 Contributing

1. Fork it
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -am 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Create a Pull Request

## 📜 License

The gem is available as open source under the [MIT License](LICENSE.txt).

## 🔗 Links

- [Configuration Guide](docs/CONFIGURATION.md)
- [API Documentation](docs/API.md)
- [Performance Benchmarks](docs/BENCHMARKS.md)

---

*Built with ❤️ by developers who understand that **performance matters** in document databases.*
