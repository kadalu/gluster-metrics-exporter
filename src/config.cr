require "yaml"

module GlusterMetricsExporter
  struct Config
    include YAML::Serializable

    property metrics_path = "/metrics",
      port = 9713,
      disable_volumes_all = false,
      gluster_executable_path = "/usr/sbin/gluster",
      disable_all_metrics = false,
      log_level = "info",
      log_dir = "/var/log/gluster-metrics-exporter",
      log_file = "exporter.log",
      gluster_log_dir = "/var/log/glusterfs",
      glusterd_dir = "/var/lib/glusterd",
      gluster_cli_socket_path = "",
      verbose = false,
      gluster_host = "",
      disabled_volumes = [] of String,
      enabled_volumes = [] of String,
      disabled_metrics = [] of String,
      enabled_metrics = [] of String,
      all_metrics = [] of String

    def initialize
    end

    def enabled?(name)
      enabled_metrics.includes?(name)
    end
  end

  class_property config = Config.new

  def self.set_enabled_metrics
    metrics = [] of String
    if @@config.disable_all_metrics
      # If --disable-all is passed then enabled list
      # will only have whatever passed as --enable
      # For example --disable-all --enable "volume_status"
      metrics = @@config.enabled_metrics
    else
      # When --disable is used to disable specific metrics
      # So, all metrics enabled except the metrics passed as `--disable`
      # For example --disable "volume_status"
      @@config.all_metrics.each do |metric|
        if !@@config.disabled_metrics.includes?(metric)
          metrics << metric
        end
      end
    end
    @@config.enabled_metrics = metrics
  end
end
