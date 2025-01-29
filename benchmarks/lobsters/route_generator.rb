# Generate a set of routes for Lobsters

class RouteGenerator
  # Take a variety of routes and randomise order, distribution and specific data items (comments, users.)
  ROUTE_GROUPS = [
    { num: 15, method: :GET, routes: ["/users"] }, # Users tree, showing order of invitation - lots of view logic
    { num: 15, method: :GET, routes: ["/active", "/newest", "/recent", "/hottest"] }, # Views of the stories by attributes
    { num: 8, method: :GET, routes: ["/rss", "/privacy", "/about", "/settings"] }, # Less-common and less-interesting routes for variation
    { num: 8, method: :GET, routes: ["/top?length=1d", "/top?length=1w", "/top?length=1y"] }, # Top stories by time
    { num: 15, method: :GET, routes: ["/hidden", "/saved", "/upvoted/stories"] }, # These all required being logged in

    # Turned off flag_warning check for /threads -- to hard to port to SQLite
    { num: 15, routes: ["/comments", "/upvoted/comments", "/threads", "/comments/:comment_id/reply"] },
    { num: 8, routes: ["/~:username/threads", "/~:username"] },

    { num: 15, routes: ["/replies", "/replies/comments", "/replies/stories", "/replies/unread"] },  # replies#stories, replies#unread, replies#comments

    { num: 15, routes: ["/s/:story_id"] },  # not including upvote/downvote because that can change story visibility dynamically

    # /categories: - admin-only
    #{ num: 50, routes: ["/stats"] },  # Stats gets a 500, needs more MySQL->SQLite porting
    # Shouldn't add /404, because that returns status 404, not 200
    # No messages added during fake-data task, so skip messages controller
    # The moderators controller isn't high-traffic, plus it has various MySQL time code that needs porting - skip it

    # POSTs are harder here. Comments seem to exist mostly in the context of stories, which changes their behaviour.
    # We'd need to do roughly what the Faker does, where we create a story and do various interaction in the context
    # of it. For now, skip it.
    #{ num: 10, method: :POST, routes: ["/comments/:comment_id/upvote"], post_opts: {} },
  ]

  def initialize(app, rng: nil)
    @app = app

    @auth_token = nil
    @resp_cookie_header = nil
    @logged_in = false

    @rng = rng || Random.new(0x1be52551fc152997)
  end

  def routes
    @routes ||= generate_routes
  end

  def visit(route)
    route["HTTP_COOKIE"] = @resp_cookie_header
    response_array = @app.call(route)
    if response_array[1]["Set-Cookie"]
      @resp_cookie_header = response_array[1]["Set-Cookie"]
    end
    response_array
  end

  ### Helpers to Query Rails Data

  def auth_token
    return @auth_token if @auth_token

    # We need to log in to get a CSRF token. We'll use the same token for all requests.
    # We also need to get the CSRF token before generating the env hashes for later requests.

    # First GET /login and set the cookie from there. CSRF token from a single session should work throughout that session.
    login_get_env = Rack::MockRequest::env_for("https://localhost/login")
    login_get_resp = @app.call(login_get_env)
    auth_token_line = login_get_resp[2].to_ary.join.lines.detect { |line| line.include?("authenticity_token") && line.include?("value") }
    @auth_token = auth_token_line.scan(/value="([^"]+)"/)[0][0]
    @resp_cookie_header = login_get_resp[1]["Set-Cookie"] #+ "; tag_filters=NOCACHE" # turn off the file cache

    @auth_token
  end

  def do_login
    return if @logged_in

    auth_token # make sure we have the auth token

    @user = User.where(email: "wiegand.michell@mertz-vonrueden.test").first

    # Let's log in as one specific user...
    # With the srand seed given in lib/tasks/fake_data.rake, we use the fake data for one of the users
    login_post_env = Rack::MockRequest::env_for("https://localhost/login", method: "POST", params: { email: @user.email, password: "ji3W36xR", authenticity_token: @auth_token })
    login_post_env["HTTP_COOKIE"] = @resp_cookie_header
    login_post_resp = @app.call(login_post_env)
    raise("Can't log in as fake user wiegand.michell: #{login_post_resp.inspect}") unless login_post_resp[0] == 302
    @resp_cookie_header = login_post_resp[1]["Set-Cookie"] #+ "; tag_filters=NOCACHE" # turn off the file cache
    @logged_in = true
  end

  private

  def generate_routes
    do_login # make sure we're logged in

    db_ids = {
      comment_id: Comment.all.pluck(:short_id),
      story_id: Story.all.select { |s| s.can_be_seen_by_user?(@user) }.map(&:short_id),
      username: User.all.pluck(:username),
    }

    # We want to randomise the order, but we need to make sure a user, comment, etc. exists when it's referenced.
    # So we start by creating a set of references to "this group is at this point in the order" and then
    # fill them in, keeping track of data items as we go along.
    group_list = ROUTE_GROUPS.flat_map { |group| (1..group[:num]).map { group } } # group[:num] references to each group
    group_list.shuffle!(random: @rng)

    route_group_envs = []
    group_list.each do |group|
      route = group[:routes].sample(random: @rng)
      if route.include?(":")
        route = route.gsub(/:(\w+)/) do |match|
          db_ids[$1.to_sym].sample(random: @rng)
        end
      end
      route_group_envs << Rack::MockRequest::env_for("https://localhost#{route}", method: group[:method])

      # Do we need to mess with our list of data items?
      # If we figure out comment upvote/flag/delete etc. we'll need some of this.
      # For now, ignore.
      #if group[:method] != :GET && group[:post_opts]
      #end
    end

    route_group_envs
  end
end
