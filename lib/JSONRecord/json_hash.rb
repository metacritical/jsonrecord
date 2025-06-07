module JSONRecord
  class JSONHash < Hash
    def method_missing(name, *args , &block)
      if self.keys.include?(name.to_s) 
        self[name.to_s]
      end
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
