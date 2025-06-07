module JSONRecord
  JSON_TABLES = {}
  COLUMN_ATTRIBUTES = {}
  
  class Base < JSONHash
    class << self
      def column(name , type=String)
        # Ensure the table entry exists before pushing
        COLUMN_ATTRIBUTES[table_name] ||= []
        
        # Always ensure 'id' is the first column if not already defined
        existing_columns = COLUMN_ATTRIBUTES[table_name].map { |col| col[0] }
        unless existing_columns.include?('id')
          COLUMN_ATTRIBUTES[table_name].unshift(['id', Integer])
        end
        
        # Add the requested column if not already exists
        unless existing_columns.include?(name.to_s)
          COLUMN_ATTRIBUTES[table_name].push [name.to_s, type]
        end
        
        # Define explicit accessor methods (German precision engineering)
        field_name = name.to_s
        
        # Define getter method
        define_method(field_name) do
          self[field_name]
        end
        
        # Define setter method  
        define_method("#{field_name}=") do |value|
          self[field_name] = value
        end
        
        # Return the column name symbol (more appropriate than :age=)
        name.to_sym
      end
    end
  end
end
