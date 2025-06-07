module JSONRecord
  JSON_TABLES = {}
  COLUMN_ATTRIBUTES = {}
  
  class Base < JSONHash
    class << self
      def column(name , type=String)
        # Ensure the table entry exists before pushing
        COLUMN_ATTRIBUTES[table_name] ||= []
        COLUMN_ATTRIBUTES[table_name].push [name.to_s,type]
        
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
      end
    end
  end
end
