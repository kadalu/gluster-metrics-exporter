require "./args"
require "./metrics_server"


def main
  args = parsed_args

  # Register URL path
  MetricsServer.default_registry.path = args.metrics_path
  MetricsServer.cluster_metrics_registry.path = args.cluster_metrics_path

  MetricsServer.start(args)
end

main
