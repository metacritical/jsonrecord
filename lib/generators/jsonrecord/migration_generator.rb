require 'rails/generators'
require 'rails/generators/migration'

module Jsonrecord
  module Generators
    class MigrationGenerator < Rails::Generators::Base
      include Rails::Generators::Migration
      
      source_root File.expand_path('templates', __dir__)
      
      argument :migration_name, type: :string
      argument :attributes, type: :array, default: [], banner: "field[:type][:index] field[:type][:index]"
      
      def self.next_migration_number(dirname)
        Time.current.strftime("%Y%m%d%H%M%S")
      end
      
      def create_migration_file
        migration_template "migration.rb.erb", "db/migrate/#{file_name}.rb"
      end
      
      private
      
      def file_name
        migration_name.underscore
      end
      
      def migration_class_name
        migration_name.camelize
      end
      
      def table_name
        # Extract table name from migration name
        if migration_name.match?(/create_(\w+)/i)
          $1.pluralize
        elsif migration_name.match?(/add_\w+_to_(\w+)/i)
          $1.pluralize
        else
          'unknown_table'
        end
      end
      
      def parsed_attributes
        attributes.map do |attr|
          name, type, options = attr.split(':')
          {
            name: name,
            type: type || 'string',
            vector: type == 'vector',
            dimensions: options&.match(/dim(\d+)/)&.captures&.first&.to_i || 384
          }
        end
      end
      
      def vector_attributes
        parsed_attributes.select { |attr| attr[:vector] }
      end
      
      def regular_attributes
        parsed_attributes.reject { |attr| attr[:vector] }
      end
    end
  end
end
