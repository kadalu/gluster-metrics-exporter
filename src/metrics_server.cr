require "http/server"
require "http/server/handlers/compress_handler"
require "crometheus"

module MetricsServer
  @@cluster_metrics_registry = Crometheus::Registry.new(false)
  @@all_metrics = [] of String

  def self.default_registry
    Crometheus.default_registry
  end

  def self.cluster_metrics_registry
    @@cluster_metrics_registry
  end

  def self.all_metrics
    @@all_metrics
  end

  def self.register_metric(name : String)
    @@all_metrics << name
  end

  def self.start(args)
    server = HTTP::Server.new([HTTP::CompressHandler.new,
                               HTTP::LogHandler.new,
                               HTTP::ErrorHandler.new(true),
                               default_registry.get_handler,
                               cluster_metrics_registry.get_handler]) do |context|
      context.response << "Hello World"
    end

    address = server.bind_tcp "0.0.0.0", args.port

    puts "Launching server at #{address}"
    puts "Press Ctrl+C to exit"
    server.listen
  end
end
