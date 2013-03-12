module JSONRecord
  class Base < JSONRecord::JSONHash
    attr_accessor :all_data
    
    def save
      self.all_data = self.class.send(:all)
      begin
        raise FileError if path_finder.nil?
        sanitize_input
        self.keys.each {|key| raise AttributeError,"Unknown Attribute #{key}" unless column_names.include? key }
        if self["id"].nil?
          increment_table_id
          self.all_data << self
          persist_data
        else
          true #Returns already persists
        end
      rescue => e
        return "#{e.message} for #{self.class}"
      end
    end
    
    def new_record?
      self["id"].nil? || self["id"] == 0
    end
    
    def persisted?
      new_record? ? false : true
    end

    def model_name
      self.class.model_name
    end

    def to_a
      [self]
    end
    
    def update_attributes(attrs={})
      self.all_data = self.class.send(:all)
      unless attrs.empty?
        sanitize_input(attrs)
        attrs.each do |key,value| 
          begin
            raise AttributeError,"Unknown Attribute" unless column_names.include? key.to_s
            data_type = self.class::COLUMN_ATTRIBUTES[self.class.to_s.downcase.pluralize].find{|i| i.first == key.to_s }
            if data_type.last  == Array
              if value.is_a?(String)
                self[key.to_s] = instance_eval(value)
              else
                self[key.to_s] = value
              end
            elsif data_type.last  == Integer
              self[key.to_s] = value.to_i
            elsif data_type.last  == String
              self[key.to_s] = value.to_s              
            end
          rescue => e
            return "#{e.message} : #{key} => #{value}"
          end
        end
        self.all_data[self.id.to_i.pred] = self
        persist_data
      end
    end
    
    def destroy
      self.all_data = self.class.send(:all)
      begin
        raise FileError if path_finder.nil?
        self.all_data.delete_if{|data| data.id == self.id }
        persist_data
      end
    end

    def to_key
      persisted? ? [self.id] : nil
    end

    private
    def sanitize_input(attrs={})
      if attrs.empty?
        key_deletion(self)
      else
        key_deletion(attrs)
      end
    end

    def key_deletion(hash)
      hash.delete_if{|key| key.to_s == 'controller' or key.to_s == 'action' }
    end

    def persist_data
      File.open(path_finder, "w+") do |file|
        file.write(all_data.to_json)
      end
      self #Returns Deleted Object
    end
  end
end
