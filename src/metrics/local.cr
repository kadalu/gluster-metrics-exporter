module GlusterMetricsExporter
  Crometheus.alias ShdGauge = Crometheus::Gauge[:hostname, :volume_name]
  Crometheus.alias LogGauge = Crometheus::Gauge[:hostname, :path]

  @@brick_cpu_percentage = BrickGauge.new(:brick_cpu_percentage, "Brick CPU Percentage")
  @@brick_memory_percentage = BrickGauge.new(:brick_memory_percentage, "Brick Memory Percentage")
  @@brick_uptime_seconds = BrickGauge.new(:brick_uptime_seconds, "Brick Uptime in Seconds")

  @@glusterd_cpu_percentage = PeerGauge.new(:glusterd_cpu_percentage, "Glusterd CPU Percentage")
  @@glusterd_memory_percentage = PeerGauge.new(:glusterd_memory_percentage, "Glusterd Memory Percentage")
  @@glusterd_uptime_seconds = PeerGauge.new(:glusterd_uptime_seconds, "Glusterd Uptime in Seconds")
  @@node_uptime_seconds = PeerGauge.new(:node_uptime_seconds, "Node Uptime in Seconds")
  @@log_dir_size_bytes = LogGauge.new(:log_directory_size_bytes, "Log directory size in bytes")

  @@shd_cpu_percentage = ShdGauge.new(:shd_cpu_percentage, "Self Heal Daemon CPU Percentage")
  @@shd_memory_percentage = ShdGauge.new(:shd_memory_percentage, "Self Heal Daemon Memory Percentage")
  @@shd_uptime_seconds = ShdGauge.new(:shd_uptime_seconds, "Self Heal Daemon Uptime in Seconds")

  @@exporter_cpu_percentage = PeerGauge.new(:exporter_cpu_percentage, "Metrics Exporter CPU Percentage")
  @@exporter_memory_percentage = PeerGauge.new(:exporter_memory_percentage, "Metrics Exporter Memory Percentage")
  @@exporter_uptime_seconds = PeerGauge.new(:exporter_uptime_seconds, "Metrics Exporter Uptime in Seconds")
  @@exporter_health = PeerGauge.new(:exporter_health, "Metrics Exporter Health")

  def self.clear_local_metrics
    @@brick_cpu_percentage.clear
    @@brick_memory_percentage.clear
    @@brick_uptime_seconds.clear
    @@glusterd_cpu_percentage.clear
    @@glusterd_memory_percentage.clear
    @@glusterd_uptime_seconds.clear
    @@shd_memory_percentage.clear
    @@shd_memory_percentage.clear
    @@shd_uptime_seconds.clear
    @@node_uptime_seconds.clear
    @@log_dir_size_bytes.clear
    @@exporter_cpu_percentage.clear
    @@exporter_memory_percentage.clear
    @@exporter_uptime_seconds.clear
    @@exporter_health.clear
  end

  handle_metrics(["local_metrics"]) do |metrics_data|
    # Reset all Metrics to avoid stale data. Careful if
    # counter type is used
    clear_local_metrics

    # If Local Metrics are not enabled
    next if !@@config.enabled?("local_metrics")

    metrics_data.volumes.each do |volume|
      volume.subvols.each_with_index do |subvol, sidx|
        subvol.bricks.each do |brick|
          brick_labels = {
            volume_name:  volume.name,
            volume_type:  volume.type,
            volume_state: volume.state,
            hostname:     brick.node.hostname,
            path:         brick.path,
            subvol_index: "#{sidx}",
          }

          if metrics_data.local_metrics[brick.node.hostname]? && metrics_data.local_metrics[brick.node.hostname].bricks[brick.path]?
            brick_local = metrics_data.local_metrics[brick.node.hostname].bricks[brick.path]

            @@brick_cpu_percentage[**brick_labels].set(brick_local.cpu_percentage)
            @@brick_memory_percentage[**brick_labels].set(brick_local.memory_percentage)
            @@brick_uptime_seconds[**brick_labels].set(brick_local.uptime_seconds)
          end
        end
      end
    end

    metrics_data.peers.each do |peer|
      peer_labels = {
        hostname: peer.hostname,
      }

      @@exporter_health[**peer_labels].set(metrics_data.exporter_health[peer.hostname])

      # If local metrics are not available
      next unless metrics_data.local_metrics[peer.hostname]?

      @@node_uptime_seconds[**peer_labels].set(metrics_data.local_metrics[peer.hostname].node_uptime_seconds)

      log_labels = peer_labels.merge({path: GlusterMetricsExporter.config.gluster_log_dir})
      @@log_dir_size_bytes[**log_labels].set(metrics_data.local_metrics[peer.hostname].log_dir_size_bytes)

      gd_metrics = metrics_data.local_metrics[peer.hostname].glusterd
      @@glusterd_cpu_percentage[**peer_labels].set(gd_metrics.cpu_percentage)
      @@glusterd_memory_percentage[**peer_labels].set(gd_metrics.memory_percentage)
      @@glusterd_uptime_seconds[**peer_labels].set(gd_metrics.uptime_seconds)

      metrics_data.local_metrics[peer.hostname].shds.each do |shd|
        # TODO: Add SHD Volname identifier when multiple SHDs exists per node
        shd_labels = peer_labels.merge({volume_name: "all"})

        @@shd_cpu_percentage[**shd_labels].set(shd.cpu_percentage)
        @@shd_memory_percentage[**shd_labels].set(shd.memory_percentage)
        @@shd_uptime_seconds[**shd_labels].set(shd.uptime_seconds)
      end

      exporter_metrics = metrics_data.local_metrics[peer.hostname].exporter
      @@exporter_cpu_percentage[**peer_labels].set(exporter_metrics.cpu_percentage)
      @@exporter_memory_percentage[**peer_labels].set(exporter_metrics.memory_percentage)
      @@exporter_uptime_seconds[**peer_labels].set(exporter_metrics.uptime_seconds)
    end
  end
end
