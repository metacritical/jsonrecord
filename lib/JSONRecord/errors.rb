module JSONRecord
  class FileError < Errno::ENOENT
  end

  class JSONRecordError < StandardError
  end
  
  class AttributeError < NoMethodError
  end
  
  class RecordNotFound < JSONRecordError
  end
  
  class TableError < NameError
  end
end
