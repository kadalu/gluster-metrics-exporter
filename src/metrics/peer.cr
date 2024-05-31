module GlusterMetricsExporter
  Crometheus.alias PeerGauge = Crometheus::Gauge[:hostname]

  @@peer_count = Crometheus::Gauge.new(:peer_count, "Number of Peers")
  @@peer_state = PeerGauge.new(:peer_state, "State of Peer")

  def self.clear_peer_metrics
    @@peer_state.clear
  end

  handle_metrics(["peer"]) do |metrics_data|
    # Reset all Metrics to avoid stale data. Careful if
    # counter type is used
    clear_peer_metrics

    # If Peer Metrics are not enabled
    next if !@@config.enabled?("peer")

    @@peer_count.set(metrics_data.peers.size)

    metrics_data.peers.each do |peer|
      # Peer State 1 => Connected, 0 => Disconnected/Unknown
      state = peer.connected? ? 1 : 0
      @@peer_state[hostname: peer.hostname].set(state)
    end
  end
end
