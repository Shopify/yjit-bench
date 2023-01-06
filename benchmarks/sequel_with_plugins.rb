require "harness"
require "tzinfo"

Dir.chdir File.join(__dir__, "sequel")
use_gemfile

require "sequel"

# Sequel with almost all plugins
Sequel.extension :date_parse_input_handler, :escaped_like, :migration, :named_timezones

DB = Sequel.sqlite

%i[
  run_transaction_hooks
  schema_caching 
  sql_comments 
  sql_log_normalizer 
  sqlite_json_ops
].each { |name| Sequel.extension name }

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

class Post < Sequel::Model
  %i[
    accessed_columns
    after_initialize
    association_dependencies
    association_lazy_eager_option
    association_multi_add_remove
    association_pks
    blacklist_security
    boolean_readers
    class_table_inheritance
    column_conflicts
    columns_updated
    csv_serializer
    dataset_associations
    delay_add_association
    dirty
    enum
    forbid_lazy_load
    input_transformer
    insert_conflict
    instance_hooks
    json_serializer
    many_through_many
    modification_detection
    nested_attributes
    optimistic_locking
    serialization_modification_detection
    split_values
    subclasses
    timestamps
    touch
    typecast_on_load
    update_or_create
    update_primary_key
    update_refresh
    validate_associated
    validation_class_methods 
    validation_contexts
    validation_helpers
    whitelist_security
  ].each { |name| plugin name }
 
  plugin :serialization, :json, :data
end

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
