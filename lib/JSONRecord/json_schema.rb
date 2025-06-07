module JSONRecord
  JSON_TABLES = {}
  COLUMN_ATTRIBUTES = {}
  
  class Base < JSONHash
    class << self
      def column(name , type=String)
        # Ensure the table entry exists before pushing
        COLUMN_ATTRIBUTES[table_name] ||= []
        COLUMN_ATTRIBUTES[table_name].push [name.to_s,type]
      end
    end
  end
end
