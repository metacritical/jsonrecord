module JSONRecord
  def define_class_and_instance_method(method_name, &block)
    define_method method_name, &block
    define_singleton_method method_name, &block
  end
  private
  def increment_table_id
    self.class.last.nil? ? self["id"] = 1 : self["id"] = self.class.last.id.next
  end
end
