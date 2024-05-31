module GlusterMetricsExporter
  Crometheus.alias ErrorGauge = Crometheus::Gauge[:name]

  @@error_count = ErrorGauge.new(:error_count, "Metrics collection errors")

  def self.clear_error_metrics
    @@error_count.clear
  end

  handle_metrics(["error"]) do |metrics_data|
    # Reset all Metrics to avoid stale data. Careful if
    # counter type is used
    clear_error_metrics

    metrics_data.errors.each do |err|
      @@error_count[name: err.name].set(1)
    end
  end
end
