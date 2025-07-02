# Generate a set of routes for Lobsters

class RouteGenerator
  # Take a variety of routes and randomise order, distribution and specific data items (comments, users.)
  ROUTE_GROUPS = [
    { num: 5, method: :GET, routes: ["/"] }, # Stacks#index
    { num: 15, method: :GET, routes: ["/:stack_id"] }, # Stacks#show
    { num: 10, method: :GET, routes: [
      "/:stack_id/tasks?since=33", # Paginated deploys
      "/:stack_id/statistics",
    ]},
    { num: 2, method: :GET, routes: [ "/:stack_id/settings" ]},

    # API routes
    { num: 5, method: :GET, routes: ["/api/stacks"] },
    { num: 10, method: :GET, routes: ["/api/stacks/:stack_id/deploys"] },
    { num: 10, method: :GET, routes: ["/api/stacks/:stack_id/commits"] },
  ]

  def initialize(app, rng: nil, api_key:)
    @app = app

    @auth_token = nil
    @resp_cookie_header = nil
    @logged_in = false

    @api_key = api_key
    creds = ["#{@api_key}:"].pack("m")
    @auth_header = "Basic #{creds}"
    @rng = rng || Random.new(0x1be52551fc152997)
  end

  def routes
    @routes ||= generate_routes
  end

  def visit(route)
    @app.call(route)
  end

  private

  def generate_routes
    db_ids = {
      stack_id: Shipit::Stack.all.map(&:to_param)
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
      env = Rack::MockRequest::env_for("https://localhost#{route}", method: group[:method])
      if route.start_with?("/api/")
        env["HTTP_AUTHORIZATION"] = @auth_header
      end
      route_group_envs << env

      # Do we need to mess with our list of data items?
      # If we figure out comment upvote/flag/delete etc. we'll need some of this.
      # For now, ignore.
      #if group[:method] != :GET && group[:post_opts]
      #end
    end

    route_group_envs
  end
end
