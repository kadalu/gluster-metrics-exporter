require "crometheus"
require "xml"

require "./metric"
require "../metrics_server"
require "./gluster_commands"

class PeerMetrics < Metric
  # Register the name
  MetricsServer.register_metric("peer")

  def self.register(args)
    # Initialize the Crometheus Metric
    PeerMetrics.new(
      args,
      :peer,
      "Peer Count, State Metrics",
      register_with: MetricsServer.cluster_metrics_registry
    )
  end

  def samples : Nil
    peers = GlusterCommands.pool_list(@args)

    # Number of Peers
    yield Crometheus::Sample.new(
      peers.size.to_f,
      labels: {:cluster => @args.cluster_name},
      suffix: "count"
    )

    # Peer State 1 => Connected, 0 => Disconnected/Unknown
    peers.each do |peer|
      # If Peer hostname is localhost then replace it with
      # the gluster_host argument passed
      host = peer.hostname == "localhost" ? @args.gluster_host : peer.hostname

      yield Crometheus::Sample.new(
        peer.state,
        labels: {:cluster => @args.cluster_name, :hostname => host},
        suffix: "state"
      )
    end
  end
end
