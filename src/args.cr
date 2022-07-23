require "option_parser"
require "yaml"

PROGNAME = "gluster-metrics-exporter"
VERSION  = {{ env("VERSION") && env("VERSION") != "" ? env("VERSION") : `git describe --always --tags --match "[0-9]*" --dirty`.chomp.stringify }}

module GlusterMetricsExporter
  def self.parse_args
    config_file = ""
    default_gluster_host = `hostname`.strip

    OptionParser.new do |parser|
      parser.banner = "Usage: #{PROGNAME} [OPTIONS]"

      parser.on("--metrics-path=URL", "Metrics Path (default: #{@@config.metrics_path})") do |url|
        @@config.metrics_path = url
      end

      parser.on("-p PORT", "--port=PORT", "Exporter Port (default: #{@@config.port})") do |port|
        @@config.port = port.to_i
      end

      # Kept this argument so that existing deployments don't fail
      parser.on("--cluster=NAME", "Cluster identifier") { |_| }

      parser.on("--gluster-host=NAME", "Gluster Host to replace `localhost` from the peer command output (default: #{default_gluster_host})") do |name|
        @@config.gluster_host = name
      end

      parser.on("-v", "--verbose", "Enable verbose output (default: #{@@config.verbose})") do
        @@config.verbose = true
      end

      parser.on("--disable-all", "Disable all Metrics (default: #{@@config.disable_all_metrics})") do
        @@config.disable_all_metrics = true
      end

      parser.on("--disable-volumes-all", "Disable all Volumes (default: #{@@config.disable_volumes_all})") do
        @@config.disable_volumes_all = true
      end

      parser.on("--enable=NAMES", "Enable specific Metric Groups") do |names|
        @@config.enabled_metrics = names.split(",")
      end

      parser.on("--disable=NAMES", "Disable specific Metric Groups (default: #{@@config.disabled_metrics})") do |names|
        @@config.disabled_metrics = names.split(",")
      end

      parser.on("--enable-volumes=NAMES", "Enable specific Volumes") do |names|
        @@config.enabled_volumes = names.split(",")
      end

      parser.on("--disable-volumes=NAMES", "Disable specific Volumes (default: #{@@config.disabled_volumes})") do |names|
        @@config.disabled_volumes = names.split(",")
      end

      parser.on("--log-level=LEVEL", "Log Level (default: #{@@config.log_level})") do |name|
        @@config.log_level = name
      end

      parser.on("--log-dir=DIR", "Log directory (default: #{@@config.log_dir})") do |name|
        @@config.log_dir = name
      end

      parser.on("--log-file=NAME", "Log file (default: #{@@config.log_file})") do |name|
        @@config.log_file = name
      end

      parser.on("--gluster-log-dir=DIR", "Gluster Log directory (default: #{@@config.gluster_log_dir})") do |name|
        @@config.gluster_log_dir = name
      end

      parser.on("--glusterd-dir=DIR", "Glusterd directory (default: #{@@config.glusterd_dir})") do |name|
        @@config.glusterd_dir = name
      end

      parser.on("--gluster-cli-path=PATH", "Gluster CLI Path (default: #{@@config.gluster_executable_path})") do |name|
        @@config.gluster_executable_path = name
      end

      parser.on("--gluster-cli-sock=SOCK", "Gluster CLI socket file (default: #{@@config.gluster_cli_socket_path})") do |name|
        @@config.gluster_cli_socket_path = name
      end

      parser.on("--version", "Show version information") do
        puts "#{PROGNAME} #{VERSION}"
        exit
      end

      parser.on("--config=FILE", "Config file") do |filename|
        config_file = filename
      end

      parser.on("-h", "--help", "Show this help") do
        puts parser
        exit
      end

      parser.unknown_args do |args|
        if args.size > 0
          STDERR.puts "Invalid args: #{args}"
          exit 1
        end
      end

      parser.invalid_option do |flag|
        STDERR.puts "Invalid Option: #{flag}"
        exit 1
      end

      parser.missing_option do |flag|
        STDERR.puts "Missing Option: #{flag}"
        exit 1
      end

      parser.parse
    end

    # Config file takes highest priority
    if config_file != ""
      if !File.exists?(config_file)
        STDERR.puts "Invalid Config file Path"
        exit 1
      end

      @@config = Config.from_yaml(File.read(config_file))
    end

    if @@config.gluster_host == ""
      gluster_hostname_file = Path.new(@@config.glusterd_dir, "hostname")

      # If hostname file is present in /var/lib/glusterd/ then use that
      # as hostname for this node. Else use the output of the hostname command.
      if File.exists?(gluster_hostname_file)
        @@config.gluster_host = File.read(gluster_hostname_file).strip
      else
        @@config.gluster_host = `hostname`.strip
      end
    end

    set_enabled_metrics
  end
end
