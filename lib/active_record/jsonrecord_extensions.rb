require 'active_record'

module ActiveRecord
  module JsonRecordExtensions
    # Vector field declaration (smart sensor installation)
    def vector_field(field_name, dimensions:, engine: nil)
      # Store vector field metadata for the model
      @vector_fields ||= {}
      @vector_fields[field_name] = {
        dimensions: dimensions,
        engine: engine || JSONRecord.vector_engine
      }
      
      # Add vector field to database schema via adapter
      if connection.respond_to?(:add_vector_field)
        connection.add_vector_field(table_name, field_name, dimensions)
      end
      
      # Define accessor methods
      define_method("#{field_name}=") do |vector|
        write_attribute(field_name, vector)
      end
      
      define_method("#{field_name}") do
        read_attribute(field_name)
      end
    end
    
    def vector_fields
      @vector_fields ||= {}
    end
    
    # Vector similarity search (semantic sensor queries)
    def similar_to(vector, options = {})
      if connection.respond_to?(:similar_to)
        # Use JsonRecord adapter's vector similarity
        results = connection.similar_to(table_name, vector, options)
        
        # Convert results to ActiveRecord instances
        ids = results.map { |r| r[:document_id] }
        records = where(id: ids).index_by(&:id)
        
        # Maintain similarity order and add similarity scores
        results.map do |result|
          record = records[result[:document_id].to_s]
          if record
            record.define_singleton_method(:similarity_score) { result[:similarity] }
            record
          end
        end.compact
      else
        # Fallback for non-JsonRecord adapters
        raise NotImplementedError, "Vector similarity requires JsonRecord adapter"
      end
    end
    
    # Chainable query methods for combining document and vector queries
    def where_similar_to(vector, options = {})
      # This would allow: User.where(active: true).where_similar_to(vector)
      # For now, delegate to similar_to
      similar_to(vector, options)
    end
  end
  
  module JsonRecordInstanceExtensions
    # Instance-level vector operations
    def similar_records(field_name, options = {})
      vector = read_attribute(field_name)
      return [] unless vector
      
      options = options.merge(field: field_name)
      self.class.similar_to(vector, options)
    end
  end
end

# Extend ActiveRecord::Base with JsonRecord vector capabilities
ActiveRecord::Base.extend(ActiveRecord::JsonRecordExtensions)
ActiveRecord::Base.include(ActiveRecord::JsonRecordInstanceExtensions)
