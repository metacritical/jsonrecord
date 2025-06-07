# JsonRecord Documentation Index 📚

*Complete guide to JsonRecord's revolutionary database architecture*

## Core Documentation

### **[README.md](../README.md)** 🚀
**Primary introduction and quick start guide**
- Overview of JsonRecord as ActiveRecord-compliant document database
- Rails integration with `database.yml` configuration
- Vector similarity search capabilities
- Installation and basic usage examples
- Performance comparisons vs SQLite/PostgreSQL

### **[ACTIVERECORD_ADAPTER.md](../ACTIVERECORD_ADAPTER.md)** 🔧
**Complete Rails integration guide**
- Drop-in replacement for SQLite/PostgreSQL
- Database configuration and migrations
- Standard ActiveRecord interface + vector extensions
- Real-world Rails application examples
- Production deployment strategies

## Advanced Architecture Documentation

### **[RELATIONS_AND_DATALOG.md](RELATIONS_AND_DATALOG.md)** 🧠
**Database theory and future evolution**
- How relations work in document databases vs RDBMS
- Three relationship patterns: Reference, Embedded, Vector
- Datomic-style datalog implementation concept
- Logic-based queries and semantic reasoning
- Revolutionary combination of Document + Vector + Datalog + ActiveRecord

### **[CONFIGURATION.md](CONFIGURATION.md)** ⚙️
**Detailed configuration options**
- Database path and storage settings
- Vector engine selection (simple/annoy/faiss)
- RocksDB optimization parameters
- Environment-specific configurations

## Architecture Deep Dives

### **Vector Storage System**
JsonRecord implements a triple-engine vector storage system:

- **`:simple`** - Pure Ruby implementation for development
- **`:annoy`** - Spotify's Approximate Nearest Neighbors for production
- **`:faiss`** - Facebook's vector search library for large scale

See [Vector Features Documentation](../README.md#vector-operations-deep-dive) for complete details.

### **Storage Architecture**
```
Documents (RocksDB/File) ← → Vector Storage ← → Similarity Index
     ↑                           ↑                    ↑
JSON documents              Embeddings          Search index
```

### **Query System**
JsonRecord supports multiple query interfaces:

1. **ActiveRecord-style** - `User.where(age: { gt: 25 }).limit(10)`
2. **Vector similarity** - `User.similar_to(vector, threshold: 0.8)`
3. **Combined queries** - Document filtering + Vector search
4. **Future: Datalog** - Logic-based reasoning with semantic relationships

## Implementation Guides

### **Getting Started**
1. Read [README.md](../README.md) for overview
2. Follow [ACTIVERECORD_ADAPTER.md](../ACTIVERECORD_ADAPTER.md) for Rails integration
3. Configure using [CONFIGURATION.md](CONFIGURATION.md)
4. Explore advanced concepts in [RELATIONS_AND_DATALOG.md](RELATIONS_AND_DATALOG.md)

### **Migration Paths**
- **From SQLite**: Change `adapter: sqlite3` to `adapter: jsonrecord`
- **From PostgreSQL**: Update database.yml and add vector fields
- **From MongoDB**: Use familiar document patterns with ActiveRecord interface

### **Performance Optimization**
- Choose appropriate vector engine for dataset size
- Use RocksDB for production (10-100x faster than file storage)
- Combine document filtering with vector search for complex queries
- Monitor vector index sizes and rebuild when needed

## Use Cases

### **Perfect for JsonRecord:**
- **AI applications** needing semantic search
- **Document databases** with flexible schemas
- **Rails applications** wanting embedded high-performance storage
- **Knowledge graphs** with vector relationships
- **Recommendation systems** combining collaborative and content filtering

### **Current Limitations:**
- No database-level foreign key constraints
- Application-level relationship resolution
- Vector operations require embedding generation
- Limited SQL compatibility (by design - uses document queries)

## Future Roadmap

### **Datalog Integration** (Proposed)
Revolutionary addition combining:
- **Logic-based queries** for complex reasoning
- **Time-travel capabilities** for temporal analysis
- **Graph traversal** with semantic relationships
- **Rule engines** for derived facts

See [RELATIONS_AND_DATALOG.md](RELATIONS_AND_DATALOG.md) for complete implementation concept.

### **Planned Features**
1. **Enhanced vector engines** with more algorithms
2. **Distributed storage** for horizontal scaling
3. **Time-series optimizations** for temporal data
4. **GraphQL interface** for modern API development
5. **Streaming queries** for real-time applications

## Contributing

### **Documentation Improvements**
- Fix typos or unclear explanations
- Add more real-world examples
- Improve code samples and explanations
- Expand use case descriptions

### **Architecture Contributions**
- Vector engine optimizations
- Query performance improvements
- New storage adapter implementations
- Datalog engine development

### **Testing and Validation**
- Performance benchmarks
- Compatibility testing with Rails versions
- Vector accuracy validation
- Memory usage profiling

## Support and Community

### **Getting Help**
1. Check existing documentation first
2. Review test files for usage examples
3. Open GitHub issues for bugs or questions
4. Contribute improvements back to project

### **Technical Support**
- **Performance issues**: Check configuration and vector engine selection
- **Rails integration**: Review ACTIVERECORD_ADAPTER.md guide
- **Vector search**: Verify embedding dimensions and engine compatibility
- **Storage problems**: Check file permissions and RocksDB installation

## Summary

**JsonRecord represents a new category of database:**
- **Document flexibility** of MongoDB
- **Performance** of RocksDB  
- **ActiveRecord compatibility** of SQLite
- **Vector search capabilities** of specialized AI databases
- **Future datalog reasoning** of Datomic

**Perfect for AI-native applications that need both structured data and semantic search capabilities in a single, high-performance, embedded database.**

---

*Documentation maintained with Russian Plumber precision and German engineering thoroughness! 🔧*