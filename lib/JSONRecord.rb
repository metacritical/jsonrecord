require_relative 'loader'

module JSONRecord
  class Base < JSONRecord::JSONHash
    extend JSONRecord
    include JSONRecord

    def initialize(args={})
      initialize_columns      
      args.each{|column| self[column.first.to_s] = column.last }
    end
  end
end
