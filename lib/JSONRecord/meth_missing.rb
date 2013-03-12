module JSONRecord
  def method_missing(name, *args , &block)
    if name.to_s[/^find_by_id$/]
      find(args)
    elsif name.to_s[/^find_by_\w+/]
      columns = $&.split('_by_').last.split('_and_')
      begin
        raise NoMethodError,"undefined method '#{$&}' for #{self}" unless (columns - self.column_names).empty?
        raise ArgumentError, "wrong number of arguments #{args.size} for #{columns.size}" unless columns.size.eql?(args.size)
        all.select { |record| record.select { |key| columns.include?(key) }.values == args }
      rescue => e
        "#{e.class} :: #{e.message}"
      end
    elsif name.to_s[/^find_all_by_\w+/]
      column = $&.split('_by_').last
       begin
         raise NoMethodError,"undefined method '#{column.last}' for #{self.class}" unless self.column_names.member?(column)
         all.select{|record| record.send(column.intern) == args.first }
       rescue => e
         "#{e.class} :: #{e.message}"
       end
    else
      begin
        unless name.to_s == "new"
          raise NoMethodError,"undefined method '#{name}' for #{self}" unless self.column_names.include? name.to_s
          raise ArgumentError, "wrong number of arguments #{args.size} for 0" unless args.empty?
        end
        return self[name.to_s] if self.column_names.include? name.to_s
      rescue => e
        puts "#{e.class} :: #{e.message}"
      end
    end
  end
end
