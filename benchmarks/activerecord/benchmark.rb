require "harness"
require "securerandom"

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

50000.times {
  Post.create!(title: SecureRandom.alphanumeric(30),
               type_name: SecureRandom.alphanumeric(10),
               key: SecureRandom.alphanumeric(10),
               body: SecureRandom.alphanumeric(100),
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
