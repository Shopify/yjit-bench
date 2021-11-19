module ApplicationHelper
    # View helpers for Discourse stubbing

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

    STUBS = {
        # In vanilla Discourse this appears unused for this template.
        # You can add plugins, but I don't see one for topic_header.
        server_plugin_outlet: "",

        render_topic_title: "Topic title placeholder",
        application_logo_url: "https://fake.app.location/logo.png",

        l: "", # So far no luck tracking this down - where is it coming from in Discourse?

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

end
