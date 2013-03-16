# JSONRecord

JSONRecord is a minimal document storage for ruby, with an active record style query interface.
It eventually aims to be as powerfull of other document stores like couchdb ... this is just a beginning.

## Installation

Add this line to your application's Gemfile:

    gem 'JSONRecord'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install JSONRecord

## Usage
    It is very easy to use jsondb as a document store in rails, create a model in rails/model 
		and inherit from JSONRecord::Base it gives few mechanisms to search and save data in json files.

		In order to generate new models an executable named jsonrecord is included: 

  `$ jsonrecord generate model apple #(make sure your model name is singular)`

		then in model/apple.rb

```ruby
			class Apple < JSONRecord::Base
			  def index
		 	  end
			end
```
			
##Methods include :

```ruby
Model.find(id) 
Model.find_by_column_name("column_value")
Model.find(id).update_attributes(:name => "pankaj" , :age => "29")
Model.find(id).destroy()
```

also ,

```ruby
Model.new({:name=> "pankaj" , :age => "29"}).save
```

In your rails model: In order to define new attributes use `column` method
i.e  column :column_name , datatype


example => `column :name`

by default if the second parameter is not defined it is taken as a string other wise datatypes can be defined as follows


```ruby
column :name, String
column :age, Number
column :marks, Array
```

Currently JSONRecord supports three datatypes String , Number , Array , More are coming ... As soon as code is modified to use
messagepack or BSON.
				 

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
