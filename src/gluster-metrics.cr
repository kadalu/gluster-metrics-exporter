require "./args"
require "./metrics_server"
require "./metrics/volume"
require "./metrics/glusterd"
require "./metrics/peer"


def enabled_metrics(args)
  metrics = [] of String
  if args.disable_all_metrics
    # If --disable-all is passed then enabled list
    # will only have whatever passed as --enable
    # For example --disable-all --enable "volume_status"
    metrics = args.enabled_metrics
  else
    # When --disable is used to disable specific metrics
    # So, all metrics enabled except the metrics passed as `--disable`
    # For example --disable "volume_status"
    MetricsServer.all_metrics.each do |metric|
      if !args.disabled_metrics.includes?(metric)
        metrics << metric
      end
    end
  end

  metrics
end


def main
  args = parsed_args

  # Register URL path
  MetricsServer.default_registry.path = args.metrics_path
  MetricsServer.cluster_metrics_registry.path = args.cluster_metrics_path

  # List of enabled metrics
  metrics_list = enabled_metrics(args)
  if metrics_list.size == 0
    STDERR.puts "No metrics enabled. Exiting.."
    exit(1)
  end

  # Initialize each metric group based on the arguments passed
  metrics_list.each do |metric|
    case metric

    when "volume"
      VolumeMetrics.register(args)

    when "glusterd"
      GlusterdMetrics.register(args)

    when "peer"
      PeerMetrics.register(args)

    end
  end

  MetricsServer.start(args)
end

main
