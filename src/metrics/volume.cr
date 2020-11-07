require "crometheus"

require "./metric"
require "../metrics_server"

class VolumeMetrics < Metric
  # Register the name
  MetricsServer.register_metric("volume")

  def self.register(args)
    # Initialize the Crometheus Metric
    VolumeMetrics.new(
      args,
      :volume,
      "Volume Metrics",
      register_with: MetricsServer.cluster_metrics_registry
    )
  end

  def samples : Nil
    yield Crometheus::Sample.new(1.0, labels: {:cluster => @args.cluster_name}, suffix: "count")
  end
end
