module JSONRecord
  def inspect
    if path_finder
      self.is_a?(Class) ? "#{self.to_s}(#{columns})" : "#{self.to_s}"
    else
      self.parent_name.eql?("JSONRecord") ? self.to_s : "#{self.to_s}(JSON Table not Found!)"
    end
  end
  
  def table_name
    if self.is_a? Class
      raise AttributeError if self.parents.include? JSONRecord
      self.to_s.pluralize.downcase
    else
      self.class.to_s.pluralize.downcase
    end
  end

  def scoped
    self.class
  end
  
  #Scoped and unscoped alias method for active record compatibility
  alias_method :unscoped , :scoped

  def connection
    self.class
  end
  
  def find(id)
    record = find_record(id.to_i)
    if record.nil? or record.empty?
      raise RecordNotFound,"Record Not Found for #{self}" rescue "#{$!.class}::#{$!.message}"
    else
      record
    end
  end
    
  def first(numb=nil)
    get_terminal_record(:first, numb) unless json_data.empty?
  end
  
  def last(numb=nil)
    get_terminal_record(:last, numb) unless json_data.empty?
  end
  
  def all
    json_data.map{|datum| send(:new , datum)}
  end

  def columns
    Hash[COLUMN_ATTRIBUTES[table_name].map{|i| [i.first,i.last.to_s]}].to_s.gsub("=>",":").gsub(/\"/,"")
  end

  def column_names
    COLUMN_ATTRIBUTES[table_name].map{|key| key.first }
  end
  
  private
  gempath = Gem::Specification.find_by_name('JSONRecord').gem_dir
  Dir.glob File.expand_path("#{gempath}/lib/tables/**/*.json", __FILE__) do |file|
    JSON_TABLES[File.basename(file)] = file
  end

  #Populate column_attrubtes hash with table_names with no fields
  JSON_TABLES.keys.each do |file_name|
    COLUMN_ATTRIBUTES[File.basename(file_name,".json")] = [["id",Integer]]
  end

  def json_data
    JSON.parse(File.read(path_finder))
  end
  
  def path_finder
    JSON_TABLES["#{table_name}.json"]
  end

  def initialize_columns
    column_names.each{|column| self[column] = nil }
  end

  def find_record(id)
    if id.is_a?(Array) or id.is_a?(Range)
      if id.is_a?(Range)
        elem = id.step
      elsif id.first.is_a?(Range)
        elem = id.first.step
      else
        elem = id.flatten
      end
      all.select{|i| i if elem.include? i["id"] }
    elsif id.is_a? Fixnum
      all.select{|i| i if i["id"] == id }.first
    end
  end

  def get_terminal_record(sym, numb)
    if numb.nil?
      send(:new, json_data.send(sym))
    else
      begin
        raise TypeError,"can't convert #{numb.class}, Expected an Integer" unless numb.is_a?(Fixnum)
        records = json_data.send(sym , numb)
        records.map{|datum| send(:new , datum)}
      rescue => e
        puts "#{e.class} :: #{e.message}"
      end
    end
  end
end
