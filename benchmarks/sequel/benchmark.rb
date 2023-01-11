require "harness"
require 'random/formatter'

Dir.chdir __dir__
use_gemfile

require "sequel"

# Sequel with common plugins & extensions
%i[
  escaped_like
  migration
  sql_log_normalizer 
  sqlite_json_ops
].each { |name| Sequel.extension name }

DB = Sequel.sqlite

DB.create_table :posts do
  primary_key :id
  String :title, null: false
  String :body
  String :type_name, null: false
  String :key, null: false
  Integer :upvotes, null: false
  Integer :author_id, null: false
  DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP
  DateTime :updated_at, default: Sequel::CURRENT_TIMESTAMP
end

%i[
  association_dependencies
  auto_validations
  json_serializer
  nested_attributes
  prepared_statements
  require_valid_schema
  subclasses
  validation_helpers
].each { |name| Sequel::Model.plugin name }

Sequel::Model.plugin :serialization, :json, :data
Sequel::Model.plugin :timestamps, update_on_create: true 

class Post < Sequel::Model 
end

10000.times {
  Post.create(title: Random.alphanumeric(30),
              type_name: Random.alphanumeric(10),
              key: Random.alphanumeric(10),
              body: Random.alphanumeric(100),
              upvotes: rand(30),
              author_id: rand(30))
}

# heat any caches
Post.where(id: 1).first.title

run_benchmark(10) do
  1.upto(1000) do |i|
    post = Post.where(id: i).first
    "#{post.title}\n#{post.body}" \
    "type: #{post.type_name}, votes: #{post.upvotes}, updated on: #{post.updated_at}"
  end
end
