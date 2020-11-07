require "crometheus"
require "xml"

require "./metric"
require "../metrics_server"

struct Peer
  property id = "", host = "", state = 0.0
end

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

  def peers_state()
    rc, resp = execute_cmd(@args.gluster_executable_path, ["pool", "list", "--xml"])
    # TODO: Log error if rc != 0
    return [] of Peer if rc != 0

    document = XML.parse(resp)

    prs = document.xpath_nodes("//peerStatus/peer")

    peers = [] of Peer
    prs.each do |pr|
      peer = Peer.new
      pr.children.each do |ele|
        case ele.name
        when "uuid"
          peer.id = ele.content.strip
        when "hostname"
          peer.host = ele.content.strip
        when "connected"
          peer.state = ele.content.strip.to_f

        end
      end

      peers << peer
    end

    peers
  end

  def samples : Nil
    peers = peers_state

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
      host = peer.host == "localhost" ? @args.gluster_host : peer.host

      yield Crometheus::Sample.new(
        peer.state,
        labels: {:cluster => @args.cluster_name, :host => host},
        suffix: "state"
      )
    end
  end
end
