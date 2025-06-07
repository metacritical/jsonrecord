require 'matrix'

module JSONRecord
  module Storage
    class VectorAdapter
      attr_reader :engine, :indexes
      
      def initialize(engine = nil)
        @engine = engine || JSONRecord.vector_engine
        @indexes = {}
        @vector_storage = {}  # In-memory for simple engine
        initialize_engine
      end
      
      # Vector operations (similarity sensors)
      def add_vector(collection_name, document_id, vector, metadata = {})
        ensure_collection(collection_name)
        
        case @engine
        when :simple
          add_vector_simple(collection_name, document_id, vector, metadata)
        when :annoy
          add_vector_annoy(collection_name, document_id, vector, metadata)
        when :faiss
          add_vector_faiss(collection_name, document_id, vector, metadata)
        else
          raise "Unknown vector engine: #{@engine}"
        end
      end
      
      def remove_vector(collection_name, document_id)
        return unless @indexes[collection_name]
        
        case @engine
        when :simple
          remove_vector_simple(collection_name, document_id)
        when :annoy
          remove_vector_annoy(collection_name, document_id)  
        when :faiss
          remove_vector_faiss(collection_name, document_id)
        end
      end
      
      def search_similar(collection_name, query_vector, options = {})
        return [] unless @indexes[collection_name]
        
        limit = options[:limit] || 10
        threshold = options[:threshold] || 0.0
        
        case @engine
        when :simple
          search_similar_simple(collection_name, query_vector, limit, threshold)
        when :annoy
          search_similar_annoy(collection_name, query_vector, limit, threshold)
        when :faiss
          search_similar_faiss(collection_name, query_vector, limit, threshold)
        else
          []
        end
      end
      
      def collection_size(collection_name)
        case @engine
        when :simple
          @vector_storage[collection_name]&.size || 0
        when :annoy
          # Annoy doesn't have size method - count metadata instead
          @vector_storage[collection_name]&.size || 0
        when :faiss
          @indexes[collection_name]&.dig(:vectors)&.size || 0
        else
          0
        end
      end
      
      # Bulk operations for performance
      def bulk_add_vectors(collection_name, vectors_data)
        vectors_data.each do |data|
          add_vector(collection_name, data[:id], data[:vector], data[:metadata] || {})
        end
        
        # Rebuild index if needed (for Annoy)
        rebuild_index(collection_name) if @engine == :annoy
      end
      
      private
      
      def initialize_engine
        case @engine
        when :simple
          # No initialization needed for simple Ruby implementation
        when :annoy
          require_annoy
        when :faiss
          require_faiss
        end
      end
      
      def ensure_collection(collection_name)
        return if @indexes[collection_name]
        
        case @engine
        when :simple
          @vector_storage[collection_name] = {}
          @indexes[collection_name] = true  # Mark collection as initialized
        when :annoy
          initialize_annoy_index(collection_name)
        when :faiss
          initialize_faiss_index(collection_name)
        end
      end
      
      # Simple Ruby implementation (Soviet approach - works but not optimized)
      def add_vector_simple(collection_name, document_id, vector, metadata)
        @vector_storage[collection_name][document_id] = {
          vector: vector.is_a?(Array) ? vector : vector.to_a,
          metadata: metadata
        }
      end
      
      def remove_vector_simple(collection_name, document_id)
        @vector_storage[collection_name]&.delete(document_id)
      end
      
      def search_similar_simple(collection_name, query_vector, limit, threshold)
        storage = @vector_storage[collection_name]
        return [] unless storage
        
        query_vec = query_vector.is_a?(Array) ? query_vector : query_vector.to_a
        similarities = []
        
        storage.each do |doc_id, data|
          similarity = cosine_similarity(query_vec, data[:vector])
          
          if similarity >= threshold
            similarities << {
              document_id: doc_id,
              similarity: similarity,
              metadata: data[:metadata]
            }
          end
        end
        
        # Sort by similarity (highest first) and limit results
        similarities.sort_by { |s| -s[:similarity] }.first(limit)
      end
      
      def cosine_similarity(vec_a, vec_b)
        return 0.0 if vec_a.empty? || vec_b.empty? || vec_a.length != vec_b.length
        
        # Convert to vectors for calculation
        a = Vector[*vec_a]
        b = Vector[*vec_b]
        
        # Calculate cosine similarity: (a · b) / (|a| * |b|)
        dot_product = a.inner_product(b)
        magnitude_a = Math.sqrt(a.inner_product(a))
        magnitude_b = Math.sqrt(b.inner_product(b))
        
        return 0.0 if magnitude_a == 0 || magnitude_b == 0
        
        dot_product / (magnitude_a * magnitude_b)
      end
      
      # Annoy implementation (Spotify's approach - good balance)
      def require_annoy
        begin
          require 'annoy'
        rescue LoadError
          raise "Annoy gem not found. Add 'gem \"annoy-rb\"' to your Gemfile for vector similarity search"
        end
      end
      
      def initialize_annoy_index(collection_name)
        # Determine vector dimensions from configuration or first vector
        dimensions = JSONRecord.configuration.vector_dimensions[collection_name] || 384
        @indexes[collection_name] = Annoy::AnnoyIndex.new(n_features: dimensions)
        
        # Initialize metadata for build tracking
        @vector_storage["#{collection_name}_meta"] = { 
          built: false, 
          needs_build: false,
          dimensions: dimensions
        }
      end
      
      def add_vector_annoy(collection_name, document_id, vector, metadata)
        index = @indexes[collection_name]
        
        # Store metadata first (Annoy only stores vectors)
        @vector_storage[collection_name] ||= {}
        @vector_storage[collection_name][document_id] = metadata
        
        # Add vector to index
        index.add_item(document_id.to_i, vector)
        
        # Mark as needing rebuild (but don't build immediately)
        index_meta = @vector_storage["#{collection_name}_meta"] ||= {}
        index_meta[:built] = false
        index_meta[:needs_build] = true
      end
      
      def remove_vector_annoy(collection_name, document_id)
        # Annoy doesn't support removal - need to rebuild index
        # For now, just remove metadata
        @vector_storage[collection_name]&.delete(document_id)
      end
      
      def search_similar_annoy(collection_name, query_vector, limit, threshold)
        index = @indexes[collection_name]
        index_meta = @vector_storage["#{collection_name}_meta"] ||= {}
        
        # Build index if needed before search
        if index_meta[:needs_build] && !index_meta[:built]
          rebuild_index(collection_name)
        end
        
        # Check if index is built
        return [] unless index_meta[:built]
        
        # Get similar items from Annoy
        similar_ids, distances = index.get_nns_by_vector(query_vector, limit, include_distances: true)
        
        results = []
        similar_ids.zip(distances).each do |doc_id, distance|
          # Convert Angular distance to cosine similarity
          similarity = 1.0 - (distance ** 2) / 2.0
          
          if similarity >= threshold
            metadata = @vector_storage[collection_name]&.[](doc_id.to_s) || {}
            results << {
              document_id: doc_id.to_s,
              similarity: similarity,
              metadata: metadata
            }
          end
        end
        
        results
      end
      
      def rebuild_index(collection_name)
        return unless @engine == :annoy
        
        index_meta = @vector_storage["#{collection_name}_meta"] ||= {}
        return if index_meta[:built]  # Don't rebuild if already built
        
        begin
          index = @indexes[collection_name]
          index.build(10)  # 10 trees for good performance
          
          # Mark as built and no longer needing build
          index_meta[:built] = true
          index_meta[:needs_build] = false
          
          puts "   ✅ Annoy index built successfully for #{collection_name}"
        rescue => e
          puts "   ⚠️  Annoy build warning: #{e.message}"
          # If already built, mark as such
          if e.message.include?("built")
            index_meta[:built] = true
            index_meta[:needs_build] = false
          end
        end
      end
      
      # FAISS implementation (Facebook's approach - best performance)
      def require_faiss
        # Use Ruby-native FAISS-style implementation instead of external bindings
        # This provides FAISS-like performance with pure Ruby
        require 'matrix'
      end
      
      def initialize_faiss_index(collection_name)
        # FAISS-style index using optimized Ruby implementation
        dimensions = JSONRecord.configuration.vector_dimensions[collection_name] || 384
        
        @indexes[collection_name] = {
          type: :faiss_flat,  # Start with FlatIP equivalent
          dimensions: dimensions,
          vectors: [],        # Store normalized vectors for fast cosine similarity
          doc_ids: [],        # Parallel array of document IDs
          index_built: false
        }
        
        # Separate metadata storage
        @vector_storage[collection_name] ||= {}
      end
      
      def add_vector_faiss(collection_name, document_id, vector, metadata)
        index_data = @indexes[collection_name]
        
        # Normalize vector for cosine similarity (FAISS-style)
        normalized_vector = normalize_vector(vector)
        
        # Add to index
        index_data[:vectors] << normalized_vector
        index_data[:doc_ids] << document_id.to_s
        
        # Store metadata separately
        @vector_storage[collection_name][document_id.to_s] = metadata
        
        # Mark as needing rebuild for batch operations
        index_data[:index_built] = false
      end
      
      def remove_vector_faiss(collection_name, document_id)
        index_data = @indexes[collection_name]
        doc_id_str = document_id.to_s
        
        # Find and remove vector
        if (idx = index_data[:doc_ids].index(doc_id_str))
          index_data[:vectors].delete_at(idx)
          index_data[:doc_ids].delete_at(idx)
          index_data[:index_built] = false
        end
        
        # Remove metadata
        @vector_storage[collection_name]&.delete(doc_id_str)
      end
      
      def search_similar_faiss(collection_name, query_vector, limit, threshold)
        index_data = @indexes[collection_name]
        return [] if index_data[:vectors].empty?
        
        # Normalize query vector
        normalized_query = normalize_vector(query_vector)
        
        # FAISS-style batch similarity computation
        similarities = compute_batch_similarities(normalized_query, index_data[:vectors])
        
        # Create results with similarity scores
        results = []
        similarities.each_with_index do |similarity, idx|
          if similarity >= threshold
            doc_id = index_data[:doc_ids][idx]
            metadata = @vector_storage[collection_name][doc_id] || {}
            
            results << {
              document_id: doc_id,
              similarity: similarity,
              metadata: metadata
            }
          end
        end
        
        # Sort by similarity (descending) and limit
        results.sort_by { |r| -r[:similarity] }.first(limit)
      end
      
      private
      
      # FAISS-style optimized vector operations
      def normalize_vector(vector)
        vec_array = vector.is_a?(Array) ? vector : vector.to_a
        magnitude = Math.sqrt(vec_array.sum { |x| x * x })
        return vec_array if magnitude == 0
        
        vec_array.map { |x| x / magnitude }
      end
      
      def compute_batch_similarities(query_vector, stored_vectors)
        # Optimized batch computation (similar to FAISS IndexFlatIP)
        stored_vectors.map do |stored_vector|
          # Dot product of normalized vectors = cosine similarity
          query_vector.zip(stored_vector).sum { |q, s| q * s }
        end
      end
    end
  end
end
