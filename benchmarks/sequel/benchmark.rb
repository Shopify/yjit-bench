require "harness"

Dir.chdir __dir__
use_gemfile

require "sequel"

# Base Sequel, no plugins
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

class Post < Sequel::Model; end

50000.times {
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
  1000.times do |i|
    Post.where(id: i + 1).first.title
  end
end
