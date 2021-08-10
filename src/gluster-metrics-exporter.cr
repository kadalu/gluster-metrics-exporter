require "crometheus"
require "kemal"

require "./config"
require "./args"
require "./metrics/*"

module GlusterMetricsExporter
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

  # Add handlers. First one will collect all the
  # metrics and the second one will export the
  # Prometheus metrics
  add_handler MetricsRunHandler.new
  add_handler Crometheus.default_registry.get_handler

  get "/metrics.json" do |env|
    MetricsData.collect.to_json
  end

  get "/_api/local-metrics" do |env|
    MetricsData.collect_local_metrics.to_json
  end

  def self.run
    parse_args

    Crometheus.default_registry.path = @@config.metrics_path
    Kemal.config.port = @@config.port
    Kemal.run
  end
end

GlusterMetricsExporter.run
