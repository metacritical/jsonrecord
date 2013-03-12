module JSONRecord
  class Base < JSONRecord::JSONHash
    extend ActiveModel::Naming
    include ActiveModel::Validations
    include ActiveModel::Conversion
  end
end
