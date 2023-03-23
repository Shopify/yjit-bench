require "harness"

Dir.chdir __dir__
use_gemfile

require "active_record"

ActiveRecord::Base.establish_connection adapter: "sqlite3", database: ":memory:"

ActiveRecord::Schema.define do
  create_table :posts, force: true do |t|
    t.string :title, null: false
    t.string :body
    t.string :type_name, null: false
    t.string :key, null: false
    t.integer :upvotes, null: false
    t.integer :author_id, null: false
    t.timestamps
  end
end

class Post < ActiveRecord::Base; end

10000.times {
  Post.create!(title: Random.alphanumeric(30),
               type_name: Random.alphanumeric(10),
               key: Random.alphanumeric(10),
               body: Random.alphanumeric(100),
               upvotes: rand(30),
               author_id: rand(30))
}

# heat any caches
Post.find(1).title

run_benchmark(10) do
  1.upto(1000) do |i|
    post = Post.find(i)
    "#{post.title}\n#{post.body}" \
    "type: #{post.type_name}, votes: #{post.upvotes}, updated on: #{post.updated_at}"
  end
end
