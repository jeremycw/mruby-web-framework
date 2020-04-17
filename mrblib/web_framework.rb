module WebFramework
  class Server < AsyncHttpServer::Server
    METHODS = {
      "GET" => R3::GET,
      "POST" => R3::POST,
      "PUT" => R3::PUT,
      "DELETE" => R3::DELETE
    }.freeze

    def initialize(port, routes)
      super(port)
      @tree = R3::Tree.new
      routes.each do |(path, method, controller, action)|
        @tree.add(path, METHODS[method], [ controller, action ])
      end
      @tree.compile
    end

    def on_request(req)
      index = req.target.index('?') || req.target.length - 1
      path = req.target[0..index]
      params, ctrl_mthd = @tree.match(path, METHODS[req.method.upcase])

      # Handle 404
      if ctrl_mthd.nil?
        res = AsyncHttpServer::Response.new
        res.status = 404
        res.body = "Not Found"
        res.set_header("Content-Type", "text/plain")
        req.respond(res)
        return
      end

      controller_class, method = ctrl_mthd
      controller = controller_class.new(req, params)
      begin
        controller.send(method)
      rescue => e
        # Log error
      end
    end
  end

  class Controller
    attr_reader :request
    attr_reader :params

    def self.default_content_type(type)
      @default_content_type = type
    end
    def self.get_default_content_type
      @default_content_type
    end

    def initialize(req, p)
      @request = req
      @params = p
    end

    def render(opts = {})
      res = AsyncHttpServer::Response.new
      res.status = opts[:status] || 200
      ct = opts[:content_type] || self.class.get_default_content_type || 'text/html'
      res.set_header("Content-Type", ct)
      res.body = opts[:body] if opts[:body]
      request.respond(res)
    end
  end
end
