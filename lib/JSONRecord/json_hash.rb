module JSONRecord
  class JSONHash < Hash
    def method_missing(name, *args , &block)
      method_name = name.to_s
      
      if method_name.end_with?('=')
        # Setter method (e.g., age=)
        field_name = method_name.chomp('=')
        self[field_name] = args.first
      elsif self.keys.include?(method_name)
        # Getter method (e.g., age)
        self[method_name]
      else
        super
      end
    end
    
    def respond_to_missing?(method_name, include_private = false)
      method_str = method_name.to_s
      method_str.end_with?('=') || self.keys.include?(method_str) || super
    end
    
    # Explicit id accessor for reliability
    def id
      self["id"]
    end
    
    def id=(value)
      self["id"] = value
    end
  end
end
