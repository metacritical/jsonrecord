module JSONRecord
  class Base < JSONHash
    def self.has_many(*args)
      begin
        args.each do |arg|
          raise TableError,"Table Not Found : #{arg}" if JSON_TABLES["#{arg}.json"].nil?
          self.class_eval(
           <<-METHOD
           def #{arg}
             puts "#{self} has_many #{arg.to_s}"
             object = "#{arg.to_s.capitalize.singularize}".constantize
             object.find_by_#{self.to_s.downcase}_id(self.id.to_s)
           end
           METHOD
         )
        end
      rescue => e
        puts "#{e.class} : #{e.message}"
      end
    end

    def self.belongs_to(*args)
      begin
        args.each do |arg|
          raise TableError,"Table Not Found : #{arg}" if JSON_TABLES["#{arg.to_s.pluralize}.json"].nil?
          self.class_eval(
           <<-METHOD
           def #{arg}
             puts "#{self} belongs_to #{arg.to_s}"
             object = "#{arg.to_s.capitalize}".constantize
             object.find(self.#{arg.to_s}_id)
           end
           METHOD
         )
        end
      rescue => e
        puts "#{e.class} : #{e.message}"
      end
    end
  end	
end
