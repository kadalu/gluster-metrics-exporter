require "log"

require "crometheus"
require "kemal"

require "./config"
require "./args"
require "./metrics/*"

module GlusterMetricsExporter
  class ExporterAPILogHandler < Kemal::BaseLogHandler
    def initialize
    end

    def call(context : HTTP::Server::Context)
      elapsed_time = Time.measure { call_next(context) }
      elapsed_text = elapsed_text(elapsed_time)
      Log.info &.emit("#{context.request.method} #{context.request.resource}", status_code: "#{context.response.status_code}", duration: "#{elapsed_text}")
      context
    end

    def write(message : String)
      Log.info { message.strip }
    end

    private def elapsed_text(elapsed)
      millis = elapsed.total_milliseconds
      return "#{millis.round(2)}ms" if millis >= 1

      "#{(millis * 1000).round(2)}µs"
    end
  end

  # A handler to be called before calling Crometheus handler
  class MetricsRunHandler < Kemal::Handler
    def call(env)
      # If route is not /metrics
      return call_next(env) unless env.request.path == GlusterMetricsExporter.config.metrics_path

      metrics_data = MetricsData.collect

      # Call each handlers with metrics_data.
      # Handlers will decide on which metrics to
      # expose as Prometheus metrics
      GlusterMetricsExporter.handlers.each do |handler|
        handler.call(metrics_data)
      end

      call_next(env)
    end
  end

  # Add Namespace so that each metrics prefixed with glusterfs_
  Crometheus.default_registry.namespace = "glusterfs"

  # Add handlers. First one will collect all the
  # metrics and the second one will export the
  # Prometheus metrics
  add_handler MetricsRunHandler.new
  add_handler Crometheus.default_registry.get_handler

  get "/metrics.json" do
    MetricsData.collect.to_json
  end

  get "/_api/local-metrics" do
    MetricsData.collect_local_metrics.to_json
  end

  def self.run
    parse_args

    Dir.mkdir_p @@config.log_dir
    logfile = Path[@@config.log_dir].join(@@config.log_file)
    # TODO: Handle Log level from CLI arg
    Log.setup(:info, Log::IOBackend.new(File.new(logfile, "a+")))

    Crometheus.default_registry.path = @@config.metrics_path
    Kemal.config.port = @@config.port
    Kemal.config.logger = ExporterAPILogHandler.new
    Kemal.run
  end
end

GlusterMetricsExporter.run
