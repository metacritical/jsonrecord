# JSONRecord

JSONRecord is a minimal document storage for rails, with an active record style query interface.
It eventually aims to be as powerfull of other document stores like couchdb ... this is just a beginning.
Inventual Roadmap is to make it independent of rails.


## Installation

Add this line to your application's Gemfile:

    gem 'JSONRecord'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install JSONRecord

## Usage

TODO: It is very easy to use jsondb as a document store in rails, create a model in rails/model and inherit from JSONRecord::Base
			it gives few mechanisms to search and save data in json files.
			
			methods include :
					 find(id) , find_by_column_name("column_value"), model_instance.update_attributes(:name => "pankaj" , :age => "29")

					 also ,

					 Model.new({:name=> "pankaj" , :age => "29"}).save


			In your rails model: In order to define new attributes use `column` method
			i.e  column :column_name , datetype

			example => column :name

			by default if the second parameter is not defined it is taken as a string other wise datatypes can be defined as follows

			column :name, String
			column :age, Number
			column :marks, Array

			Currently JSONRecord supports three datatypes String , Number , Array , More are coming ... As soon as code is modified to use
			messagepack or BSON.
					 

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
