require "glustercli"

module GlusterMetricsExporter
  class MetricsData
    include JSON::Serializable

    property volumes = [] of GlusterCLI::VolumeInfo,
      peers = [] of GlusterCLI::NodeInfo,
      local_metrics = Hash(String, GlusterCLI::LocalMetrics).new

    def self.collect
      data = MetricsData.new
      cli = GlusterCLI::CLI.new
      cli.gluster_executable = GlusterMetricsExporter.config.gluster_executable_path

      if GlusterMetricsExporter.config.gluster_host != ""
        cli.current_hostname = GlusterMetricsExporter.config.gluster_host
      end

      if GlusterMetricsExporter.config.enabled?("volume")
        status_collect = false
        if GlusterMetricsExporter.config.enabled?("volume_status")
          status_collect = true
        end

        data.volumes = cli.list_volumes(status: status_collect)
      end

      if GlusterMetricsExporter.config.enabled?("peer")
        data.peers = cli.list_peers
      end

      # TODO: API calls concurrently
      data.peers.each do |peer|
        url = "http://#{peer.hostname}:#{GlusterMetricsExporter.config.port}/_api/local-metrics"
        # TODO: Handle HTTP error and Connection refused errors
        response = HTTP::Client.get url

        data.local_metrics[peer.hostname] = GlusterCLI::LocalMetrics.from_json(response.body)
      end

      data
    end

    def self.collect_local_metrics
      cli = GlusterCLI::CLI.new
      cli.local_metrics
    end

    def initialize
    end
  end

  @@handlers = [] of MetricsData -> Nil

  def self.handlers
    @@handlers
  end

  def self.handle_metrics(tags : Array(String), &block : MetricsData -> Nil)
    @@config.all_metrics.concat(tags)
    @@handlers << block
  end

  def self.execute_cmd(cmd, args)
    stdout = IO::Memory.new
    stderr = IO::Memory.new
    status = ::Process.run(cmd, args: args, output: stdout, error: stderr)
    if status.success?
      {status.exit_code, stdout.to_s, stderr.to_s}
    else
      {status.exit_code, stdout.to_s, stderr.to_s}
    end
  end
end
