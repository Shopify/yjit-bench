# This controller will never be called for a real route.
# It's not even hooked into the routing table. But we're
# using it for non-HTTP-request view rendering, just as
# we would if it were for ActionCable.
#
# For details of how out-of-controller rendering works,
# see https://www.bigbinary.com/blog/rendering-views-outside-of-controllers-in-rails-5

# We make a lot of Structs as stub data.

company_struct = Struct.new(:presence)
ss_struct = Struct.new(:display_name_on_posts, :company_name, :title)
SiteSetting = ss_struct.new(false, company_struct.new(false), "settings title")

class FakeDiscourseController < ApplicationController
    attr_reader :stub_assigns

    def self.view_stub
        return @stub_assignments if @stub_assignments

        # The topic_view seems to hold the details for *this* view of *this* topic.
        # It holds most of the interesting stubs for this view.

        @stub_assignments = {}
        topic_struct = Struct.new(:id, :slug)
        topic = topic_struct.new(4321, "lunches_forever")
        topic_view_struct = Struct.new(:topic, :title, :posts, :url, :image_url, :post_custom_fields, :link_counts, :prev_page, :next_page, :read_time, :like_count, :published_time, :page_title, :print)
        topic_view_obj = topic_view_struct.new(topic, "Lunches Forever", [], "/fake/topic/url", "https://fake.image.url/fake.png", {}, {}, nil, nil, 0.0, 0, DateTime.now, "Viewing Page", false)
        def topic_view_obj.summary(*ignored); ""; end # Summary for meta tags
        @stub_assignments[:topic_view] = topic_view_obj

        # We'll create a user and some posts and then add them to the topic view object.
        user_struct = Struct.new(:name, :username)
        u = user_struct.new("Ali S. Fakenamington", "ali_s")
        post_body = "what I had for lunch was a sandwich. But then the day before,<br/>\n" * 5 + "..."
        post_struct = Struct.new(:user, :id, :topic, :action_code, :image_url, :created_at, :version, :post_number, :hidden, :cooked, :like_count, :reply_count)
        post = post_struct.new(u, 1234, topic_view_obj, nil, "https://fake.image.url/fake.png", DateTime.now, 1, 1, false, post_body, 0, 0)
        3.times { topic_view_obj.posts << post }

        # Now add breadcrumbs and tags, which also get instance variables.

        @stub_assignments[:breadcrumbs] = [ { url: "https://placeholder", color: "blue", name: "PageDivision" } ] * 3
        tag_struct = Struct.new(:name)
        @stub_assignments[:tags] = [ tag_struct.new("tag-name") ] * 3

        @stub_assignments
    end

    def initialize
        @stub_assigns = FakeDiscourseController.view_stub
    end

    # This is used as Discourse.base_url (see below)
    def self.base_url
        "https://fake.discourse.url"
    end

end

# By assigning this, we make sure that (e.g.) Discourse.base_url can be
# defined on the controller, but be visible from the view.
Discourse = FakeDiscourseController
