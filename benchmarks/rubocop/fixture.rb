# frozen_string_literal: true

# Style mistakes such as indentation errors are intentional, so that the diagnostics request finds at least a few
# violations

module Blog
  # :nodoc:
  class User
    extend T::Sig

    # Set the right table name for this model
  configure_model do |config|
    T.bind(self, Model::Config)

    config.table_name = "blog_users"
      config.primary_key = :user_id
      config.db = "blog"
      config.adapter.with_defaults do |adapter_config|
        adapter_config.name = :sqlite
      end
    end

    has_many :favorites, class_name: "Post"

    # Users are initialized with an email
    # @param [String] email
    # @return [User]
    sig { params(email: String).void }
    def initialize(email)
      @email = email
    end
  end

  # :nodoc:
  class Comment
    extend T::Sig

    # Set the right table name for this model
    configure_model do |config|
      T.bind(self, Model::Config)

      config.table_name = "blog_comments"
      config.primary_key = :comment_id
      config.db = "blog"
      config.adapter.with_defaults do |adapter_config|
        adapter_config.name = :sqlite
      end
    end

    belongs_to :post

    # Comments are initialized with a user and a body
    # @param [User] user
    # @param [String] body
    # @return [Comment]
    sig { params(user: User, body: String).void }
    def initialize(user, body)
      @user = user
      @body = body
    end
  end

  # :nodoc:
  class Author
    extend T::Sig
    include SomeConcern

    LIST = T.let([
      :foo,
      :bar,
      :baz,
    ], T::Array[Symbol])

    has_many :posts

    validates :name, :subscribed, presence: true

    enum status: { subscribed: 0, unsubscribed: 1 }

    sig { returns(String) }
    attr_reader :name

    # Set the right table name for this model
    configure_model do |config|
      T.bind(            self, Model::Config)

      config.table_name = "blog_authors"
      config.primary_key = :author_id
      config.db = "blog"
      config.adapter.with_defaults do |adapter_config|
        adapter_config.name = :sqlite
      end
    end

    # Authors are initialized with a name
    # @param [String] name
    # @return [Author]
    sig { params(name: String).void }
    def initialize(name)
      @name = name
    end
  end

  # :nodoc:
  class Post
    extend T::Sig
    include SomeModule

    CONSTANT = T.let(123, Integer)

    belongs_to :author
    has_many :comments
    has_and_belongs_to_many :labels

    validates :title, presence: true
    validate :author_is_subscribed, if: -> { private? }

    before_create :set_temporary_title

    enum status: { draft: 0, published: 1, archived: 2 }
    enum visibility: { public: 0, private: 1 }

    scope :from_author, ->(author) { where(author: author) }
    scope :visible, lambda do
      where(visibility: :public)
    end

    sig {


    returns(String) }
    attr_reader :title

    sig { returns(String) }
    attr_reader :body

    # Set the right table name for this model
    configure_model do |config|
      T.bind(self, Model::Config)

      config.table_name = "blog_posts"
      config.primary_key = :post_id
      config.db = "blog"
      config.adapter.with_defaults do |adapter_config|
        adapter_config.name = :sqlite
      end
    end

    # Posts are initialized with a title and a body
    # @param [String] title
    # @param [String] body
    # @return [Post]
    sig { params(title: String, body: String).void }
    def initialize(title, body)
      @title = title
      @body = body
      @score = T.let(nil, T.nilable(Float))
    end

    # Find posts from the same author excluding this one
    # @return [Array<Post>]
    sig { returns(T::Array[Post]) }
    def from_same_author
      Post.where(author_id: author_id).not(id: id)
    end

    # Mark the post as published and notify all subscribers
    # @return void
    sig { void }
    def publish!
      published!
      notify_subscribers
    end

    # Look for posts similar to this one
    # @return [Array<Post>]
    sig { returns(T::Array[Post]) }
    def similar_posts
      Post.where("title LIKE ?", "%#{title}%").select do |post|
        (post.labels.map(&:name) - self.labels.map(&:name)).any?
      end
    end

    # Calculates the post score based on the average score of all of its comments
    # @return [Float]
    sig { returns(Float) }
    def score
      @score ||= T.let(
        comments.map(&:score).avg,
        T.nilable(Float)
      )
    end

    private

    sig { void }
    def author_is_subscribed
      author.subscribed?
    end

    sig { void }
    def notify_subscribers
      NotifierJob.perform_later(self)
    end

    sig { void }
    def set_temporary_title
      self.title = "New post" if self.title.nil? && draft?
    end
  end
end
