require 'time'  # For iso8601 method

module JSONRecord
  class Base < JSONRecord::JSONHash
    attr_accessor :similarity_score
    
    def save
      begin
        sanitize_input
        validate_attributes
        
        if new_record?
          # Create new record (German precision insertion)
          generate_id if self["id"].nil?
          document_data = prepare_document_data
          
          # Save to RocksDB
          self.class.document_storage.put_document(
            self.class.table_name, 
            self["id"], 
            document_data
          )
          
          # Save vectors if any
          save_vectors if has_vector_fields?
          
          # Run callbacks
          run_callbacks(:after_create)
          
        else
          # Update existing record (German precision modification)
          document_data = prepare_document_data
          
          # Update in RocksDB
          self.class.document_storage.put_document(
            self.class.table_name,
            self["id"],
            document_data
          )
          
          # Update vectors if changed
          update_vectors if vector_fields_changed?
          
          # Run callbacks
          run_callbacks(:after_update)
        end
        
        # Run callbacks
        run_callbacks(:after_save)
        
        self
      rescue => e
        puts "Save failed for #{self.class}: #{e.message}"
        false
      end
    end
    
    def new_record?
      self["id"].nil? || self["id"] == 0
    end
    
    def persisted?
      !new_record?
    end

    def model_name
      self.class.model_name
    end

    def to_a
      [self]
    end
    
    def update_attributes(attrs = {})
      return true if attrs.empty?
      
      begin
        sanitize_input(attrs)
        
        attrs.each do |key, value|
          key_str = key.to_s
          
          # Validate attribute exists (if schema defined)
          if defined_columns? && !column_names.include?(key_str)
            raise AttributeError, "Unknown attribute: #{key_str}"
          end
          
          # Type casting based on schema (if defined)
          self[key_str] = cast_attribute_value(key_str, value)
        end
        
        save
      rescue => e
        puts "Update failed: #{e.message}"
        false
      end
    end
    
    def destroy
      begin
        raise "Cannot destroy new record" if new_record?
        
        # Remove from RocksDB
        self.class.document_storage.delete_document(
          self.class.table_name,
          self["id"]
        )
        
        # Remove vectors
        remove_vectors if has_vector_fields?
        
        # Run callbacks
        run_callbacks(:after_destroy)
        
        # Freeze object
        freeze
        
        self
      rescue => e
        puts "Destroy failed: #{e.message}"
        false
      end
    end

    def to_key
      persisted? ? [self.id] : nil
    end
    
    def reload
      raise "Cannot reload new record" if new_record?
      
      document = self.class.document_storage.get_document(
        self.class.table_name,
        self["id"]
      )
      
      if document
        # Clear current attributes and load fresh data
        clear
        document.each { |key, value| self[key] = value }
        self
      else
        raise "Record not found"
      end
    end
    
    # Vector field accessors (smart sensor readings)
    def similarity_score
      @similarity_score
    end
    
    def similarity_score=(score)
      @similarity_score = score
    end

    private
    
    def sanitize_input(attrs = {})
      target_hash = attrs.empty? ? self : attrs
      key_deletion(target_hash)
    end

    def key_deletion(hash)
      # Remove Rails controller/action params
      hash.delete_if { |key| %w[controller action].include?(key.to_s) }
    end
    
    def validate_attributes
      return true unless defined_columns?
      
      # Basic validation - can be extended
      self.keys.each do |key|
        unless column_names.include?(key.to_s)
          raise AttributeError, "Unknown attribute: #{key}"
        end
      end
      
      true
    end
    
    def prepare_document_data
      # Convert to plain hash for storage
      document_data = {}
      self.each { |key, value| document_data[key] = value }
      
      # Add timestamps
      now = Time.now.utc.iso8601
      document_data["updated_at"] = now
      document_data["created_at"] ||= now
      
      # CRITICAL: Add table_name for filtering in all_documents
      document_data["_table"] = self.class.table_name
      
      document_data
    end
    
    def generate_id
      # Generate unique ID (German precision numbering)
      max_id = get_max_id_from_storage
      self["id"] = max_id + 1
    end
    
    def get_max_id_from_storage
      # Get highest ID from existing documents
      all_docs = self.class.document_storage.find_documents(self.class.table_name)
      return 0 if all_docs.empty?
      
      all_docs.map { |doc| doc["id"].to_i }.max || 0
    end
    
    def has_vector_fields?
      self.class.vector_fields.any?
    end
    
    def vector_fields_changed?
      @vector_fields_changed && @vector_fields_changed.any?
    end
    
    def save_vectors
      self.class.vector_fields.each do |field_name, config|
        vector = send(field_name)  # Use correct field name without _vector suffix
        next unless vector
        
        collection_name = "#{self.class.table_name}_#{field_name}"
        self.class.vector_storage.add_vector(
          collection_name,
          self["id"],
          vector,
          { updated_at: Time.now.utc.iso8601 }
        )
      end
    end
    
    def update_vectors
      return unless @vector_fields_changed
      
      @vector_fields_changed.each do |field_name|
        vector = send(field_name)  # Use correct field name
        collection_name = "#{self.class.table_name}_#{field_name}"
        
        if vector
          self.class.vector_storage.add_vector(
            collection_name,
            self["id"],
            vector,
            { updated_at: Time.now.utc.iso8601 }
          )
        else
          self.class.vector_storage.remove_vector(collection_name, self["id"])
        end
      end
      
      @vector_fields_changed = []
    end
    
    def remove_vectors
      self.class.vector_fields.each do |field_name, config|
        collection_name = "#{self.class.table_name}_#{field_name}"
        self.class.vector_storage.remove_vector(collection_name, self["id"])
      end
    end
    
    def defined_columns?
      defined?(COLUMN_ATTRIBUTES) && COLUMN_ATTRIBUTES[self.class.table_name]
    end
    
    def column_names
      self.class.column_names
    end
    
    def cast_attribute_value(key, value)
      return value unless defined_columns?
      
      # Find data type from schema
      column_def = COLUMN_ATTRIBUTES[self.class.table_name]&.find { |col| col.first == key }
      return value unless column_def
      
      data_type = column_def.last
      
      case data_type
      when Array
        value.is_a?(String) ? eval(value) : value
      when Integer
        value.to_i
      when String
        value.to_s
      when Float
        value.to_f
      else
        value
      end
    end
    
    def run_callbacks(callback_type)
      # Placeholder for callback system
      # In full implementation, this would run before_save, after_save, etc.
    end
  end
end
