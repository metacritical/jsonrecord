module JSONRecord
  class QueryBuilder
    attr_reader :model_class, :document_conditions, :vector_conditions, 
                :order_conditions, :limit_value, :offset_value
    
    def initialize(model_class)
      @model_class = model_class
      @document_conditions = []
      @vector_conditions = []
      @order_conditions = []
      @limit_value = nil
      @offset_value = 0
    end
    
    # Document filtering (RocksDB queries)
    def where(conditions)
      case conditions
      when Hash
        @document_conditions << normalize_conditions(conditions)
      when String
        # Raw condition string for complex queries
        @document_conditions << { _raw: conditions }
      end
      self  # Enable method chaining like German precision engineering
    end
    
    # Vector similarity search (FAISS/Vector queries)
    def similar_to(vector, options = {})
      @vector_conditions << {
        vector: vector,
        field: options[:field] || :default,
        threshold: options[:threshold] || 0.0,
        limit: options[:limit] || 50,  # Pre-filter before document filtering
        algorithm: options[:algorithm] || :cosine
      }
      self
    end
    
    def semantic_search(text, options = {})
      # Placeholder for text-to-vector conversion
      # In real implementation, this would use an embedding model
      raise NotImplementedError, "Semantic search requires embedding model integration"
    end
    
    # Result ordering and limiting
    def order(field_or_hash)
      case field_or_hash
      when Symbol, String
        @order_conditions << { field: field_or_hash, direction: :asc }
      when Hash
        field_or_hash.each do |field, direction|
          @order_conditions << { field: field, direction: direction }
        end
      end
      self
    end
    
    def order_by_similarity
      @order_conditions << { type: :similarity, direction: :desc }
      self
    end
    
    def limit(count)
      @limit_value = count.to_i
      self
    end
    
    def offset(count)
      @offset_value = count.to_i
      self
    end
    
    # Execution methods (where the plumbing magic happens)
    def first
      limit(1).to_a.first
    end
    
    def last
      # For document queries, we need to reverse order
      results = to_a
      results.last
    end
    
    def all
      to_a
    end
    
    def count
      execute_query.size
    end
    
    def exists?
      limit(1).count > 0
    end
    
    def to_a
      results = execute_query
      apply_ordering(results)
      apply_limit_offset(results)
    end
    
    # Query execution strategies (German engineering decision making)
    def execute_query
      if vector_only_query?
        execute_vector_only_query
      elsif document_only_query?
        execute_document_only_query
      else
        execute_hybrid_query
      end
    end
    
    private
    
    def vector_only_query?
      @vector_conditions.any? && @document_conditions.empty?
    end
    
    def document_only_query?
      @document_conditions.any? && @vector_conditions.empty?
    end
    
    def execute_document_only_query
      # Pure RocksDB document filtering (like checking water pressure in specific pipes)
      storage = @model_class.document_storage
      table_name = @model_class.table_name
      
      if @document_conditions.empty?
        # Get all documents
        documents = storage.find_documents(table_name)
      else
        # Apply document conditions
        merged_conditions = merge_document_conditions
        documents = storage.find_documents(table_name, merged_conditions)
      end
      
      # Convert to model instances
      documents.map { |doc| @model_class.new(doc) }
    end
    
    def execute_vector_only_query
      # Pure vector similarity search (like checking temperature sensors)
      vector_adapter = @model_class.vector_storage
      table_name = @model_class.table_name
      
      results = []
      
      @vector_conditions.each do |condition|
        collection_name = vector_collection_name(condition[:field])
        similar_docs = vector_adapter.search_similar(
          collection_name,
          condition[:vector],
          limit: condition[:limit],
          threshold: condition[:threshold]
        )
        
        # Load full documents from RocksDB
        document_storage = @model_class.document_storage
        similar_docs.each do |result|
          doc = document_storage.get_document(table_name, result[:document_id])
          if doc
            model_instance = @model_class.new(doc)
            model_instance.instance_variable_set(:@similarity_score, result[:similarity])
            results << model_instance
          end
        end
      end
      
      # Remove duplicates and sort by similarity
      results.uniq { |r| r.id }.sort_by { |r| -(r.instance_variable_get(:@similarity_score) || 0) }
    end
    
    def execute_hybrid_query
      # Combined document + vector search (German precision meets Soviet efficiency)
      
      # Strategy 1: Filter documents first, then vector search within results
      if should_filter_documents_first?
        candidate_documents = execute_document_only_query
        candidate_ids = candidate_documents.map(&:id)
        
        # Perform vector search only within candidates
        filtered_vector_results = []
        
        @vector_conditions.each do |condition|
          collection_name = vector_collection_name(condition[:field])
          vector_adapter = @model_class.vector_storage
          
          # This would be optimized in real FAISS implementation
          all_similar = vector_adapter.search_similar(
            collection_name,
            condition[:vector],
            limit: condition[:limit] * 10,  # Get more candidates
            threshold: condition[:threshold]
          )
          
          # Filter to only candidates
          candidate_similar = all_similar.select do |result|
            candidate_ids.include?(result[:document_id].to_s)
          end
          
          filtered_vector_results.concat(candidate_similar)
        end
        
        # Load and return results
        results = []
        filtered_vector_results.each do |result|
          doc = candidate_documents.find { |d| d.id.to_s == result[:document_id].to_s }
          if doc
            doc.instance_variable_set(:@similarity_score, result[:similarity])
            results << doc
          end
        end
        
        results.uniq { |r| r.id }
        
      else
        # Strategy 2: Vector search first, then document filtering
        vector_results = execute_vector_only_query
        
        # Apply document conditions to vector results
        return vector_results if @document_conditions.empty?
        
        merged_conditions = merge_document_conditions
        vector_results.select { |doc| matches_document_conditions?(doc, merged_conditions) }
      end
    end
    
    def should_filter_documents_first?
      # Heuristic: if document conditions are very selective, filter first
      # This is where query optimization would go in production system
      
      selective_conditions = @document_conditions.count do |cond|
        cond.any? do |field, value|
          # Consider equality conditions as selective
          !value.is_a?(Hash) && !value.is_a?(Range)
        end
      end
      
      # If more than half conditions are selective, filter documents first
      selective_conditions > @document_conditions.size / 2
    end
    
    def merge_document_conditions
      # Combine all document conditions into single hash
      merged = {}
      
      @document_conditions.each do |condition_hash|
        merged.merge!(condition_hash)
      end
      
      merged
    end
    
    def matches_document_conditions?(document, conditions)
      # Check if document matches all conditions
      conditions.all? do |field, expected_value|
        actual_value = get_nested_field_value(document, field)
        
        case expected_value
        when Hash
          # Handle complex conditions like { gte: 5 }
          expected_value.all? do |operator, value|
            compare_values(actual_value, operator, value)
          end
        else
          actual_value == expected_value
        end
      end
    end
    
    def get_nested_field_value(document, field_path)
      # Handle nested field access like "experience.years"
      keys = field_path.to_s.split('.')
      
      keys.reduce(document) do |obj, key|
        case obj
        when Hash
          obj[key] || obj[key.to_sym]
        when JSONRecord::Base
          obj.respond_to?(key) ? obj.send(key) : obj[key]
        else
          nil
        end
      end
    end
    
    def compare_values(actual, operator, expected)
      return false if actual.nil?
      
      case operator.to_sym
      when :gte then actual >= expected
      when :gt  then actual > expected
      when :lte then actual <= expected
      when :lt  then actual < expected
      when :includes
        if actual.respond_to?(:include?)
          actual.include?(expected)
        else
          false
        end
      when :near
        # Simplified geo distance - real implementation would use proper geo calculations
        return false unless actual.is_a?(Hash) && expected.is_a?(Array)
        lat_diff = (actual['lat'] || actual[:lat]).to_f - expected[0].to_f
        lng_diff = (actual['lng'] || actual[:lng]).to_f - expected[1].to_f
        distance = Math.sqrt(lat_diff**2 + lng_diff**2)
        distance <= 1.0  # Simple distance threshold
      else
        false
      end
    end
    
    def normalize_conditions(conditions)
      # Convert string keys to symbols and handle special cases
      normalized = {}
      
      conditions.each do |key, value|
        normalized_key = key.to_s
        normalized[normalized_key] = value
      end
      
      normalized
    end
    
    def vector_collection_name(field)
      # Generate collection name for vector field
      "#{@model_class.table_name}_#{field}"
    end
    
    def apply_ordering(results)
      return results if @order_conditions.empty?
      
      @order_conditions.each do |order_condition|
        case order_condition[:type]
        when :similarity
          # Sort by similarity score (already handled in vector search)
          results.sort_by! do |doc| 
            score = doc.instance_variable_get(:@similarity_score) || 0
            order_condition[:direction] == :desc ? -score : score
          end
        else
          # Sort by document field
          field = order_condition[:field]
          results.sort_by! do |doc|
            value = get_nested_field_value(doc, field)
            # Handle nil values
            value = order_condition[:direction] == :desc ? '' : 'zzz' if value.nil?
            order_condition[:direction] == :desc ? [value].reverse : value
          end
        end
      end
      
      results
    end
    
    def apply_limit_offset(results)
      start_index = @offset_value
      end_index = @limit_value ? start_index + @limit_value : results.size
      
      results[start_index...end_index] || []
    end
  end
end
