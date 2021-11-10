require 'harness'
Dir.chdir __dir__
use_gemfile

# Erubi, and its relatives Erubis and ERB, operate in basically the
# same way: they turn a template in ERB format into Ruby code which,
# when evaluated, returns a string with all the appropriate
# substitutions. You can use arbitrary Ruby code in ERB because
# it's running it with eval. It *is* just arbitrary Ruby code,
# and the static parts are just a string that gets added to the
# output.

# The differences in speed between implementations are just in
# how that code is generated and evaluated.

# The ERB template here is taken from Discourse, a large piece
# of Ruby on Rails forum software. We're not going to import
# a big chunk of Rails and/or Discourse - we're just going
# to benchmark its Erubi functionality, not the underlying
# methods. So: we stub the data and methods in Discourse's
# views using placeholder objects.

# Note: Rails does a weird thing where it will capture the
# output of form blocks sometimes based on the Ruby code
# it sees. Erubi doesn't do that. This specific ERB
# template doesn't use that functionality, so it doesn't
# affect the output. But many Rails views *do* use it, and that
# *does* affect performance in Rails. So: keep in mind
# that raw Erubi performance is not identical to in-Rails
# Erubi performance.

TEMPLATE_FILE = "topics_show.html.erb"
#TEMPLATE_FILE = "simple_template.erb"

require "date"

require "erubi"

# ActiveSupport defines a lot of methods to do a lot of things.
# Rails always includes all of it. How little can we get away with using?
require "active_support/core_ext/object/blank"
require "active_support/core_ext/date_time/conversions"
require "active_support/core_ext/string/output_safety"

class StubTopicView
  company_struct = Struct.new(:presence)
  ss_struct = Struct.new(:display_name_on_posts, :company_name, :title)
  SiteSetting = ss_struct.new(false, company_struct.new(false), "settings title")

  def initialize
    topic_struct = Struct.new(:id, :slug)
    topic = topic_struct.new(4321, "lunches_forever")

    # The topic_view seems to hold the details for *this* view of *this* topic.
    topic_view_struct = Struct.new(:topic, :title, :posts, :url, :image_url, :post_custom_fields, :link_counts, :prev_page, :next_page, :read_time, :like_count, :published_time, :page_title, :print)
    @topic_view = topic_view_struct.new(topic, "Lunches Forever", [], "/fake/topic/url", "https://fake.image.url/fake.png", {}, {}, nil, nil, 0.0, 0, DateTime.now, "Viewing Page", false)
    def @topic_view.summary(*ignored); ""; end # Summary for meta tags

    @breadcrumbs = [ { url: "https://placeholder", color: "blue", name: "PageDivision" } ] * 3

    tag_struct = Struct.new(:name)
    @tags = [ tag_struct.new("tag-name") ] * 3

    user_struct = Struct.new(:name, :username)
    u = user_struct.new("Ali S. Fakenamington", "ali_s")

    post_body = "what I had for lunch was a sandwich. But then the day before,<br/>\n" * 5 + "..."
    post_struct = Struct.new(:user, :id, :topic, :action_code, :image_url, :created_at, :version, :post_number, :hidden, :cooked, :like_count, :reply_count)
    post = post_struct.new(u, 1234, @topic_view, nil, "https://fake.image.url/fake.png", DateTime.now, 1, 1, false, post_body, 0, 0)
    3.times { @topic_view.posts << post }
  end

  def self.base_url
    "https://fake.discourse.url"
  end

  STUBS = {
    # In vanilla Discourse this appears unused for this template.
    # You can add plugins, but I don't see one for topic_header.
    server_plugin_outlet: "",

    render_topic_title: "Topic title placeholder",
    application_logo_url: "https://fake.app.location/logo.png",

    l: "", # So far no luck tracking this down - where is it coming from?

    # These calculate tags for the header
    auto_discovery_link_tag: "",
    crawlable_meta_data: "",

    raw: "",
  }
  STUBS.each do |method_name, stub_value|
    define_method(method_name) do |*args_ignored|
      stub_value.freeze
    end
  end

  def include_crawler_content?
    true
  end

  # For localizing user-visible strings from internal tags
  def t(identifier, *ignored)
    "#{identifier}, but localized"
  end

  def gsub_emoji_to_unicode(item)
    item
  end

  # In Rails, this method renders the result and stores it for use elsewhere.
  # In this template we'll render the result and throw it away.
  def content_for(*args)
    yield
  end
end
Discourse = StubTopicView

view = StubTopicView.new

def evaluate_erubi(view_stub)
  @template ||= File.read TEMPLATE_FILE
  src = Erubi::Engine.new(@template).src
  view_stub.instance_eval(src)
end

def erubi_source
  @template ||= File.read TEMPLATE_FILE
  Erubi::Engine.new(@template).src
end

EXPECTED_TEXT_SIZE = 9369
EXPECTED_SOURCE_SIZE = 9509

template = File.read TEMPLATE_FILE
src = Erubi::Engine.new(template).src

run_benchmark(10) do
  500.times do
    #result = view.instance_eval(src)
    #raise "Wrong generated texst size: #{result.size}!" unless result.size == EXPECTED_TEXT_SIZE

    # Generate and evaluate Ruby source for template
    result = evaluate_erubi(view)
    #raise "Wrong generated text size: #{result.size}!" unless result.size == EXPECTED_TEXT_SIZE

    ## Generate Ruby source for template, but do not evaluate
    #src = erubi_source
    #raise "Wrong generated source size: #{src.size}!" unless src.size == EXPECTED_SOURCE_SIZE

  end
end
