require "crometheus"

require "./metric"
require "../metrics_server"

class GlusterdMetrics < Metric
  # Register the name
  MetricsServer.register_metric("glusterd")

  def self.register(args)
    # Initialize the Crometheus Metric
    GlusterdMetrics.new(
      args,
      :glusterd,
      "CPU, Memory and Uptime metrics of Glusterd"
    )
  end

  def samples : Nil
    cmdout = `ps --no-header -ww -o pcpu,pmem,rsz,vsz,etimes,comm -C glusterd`
    return if cmdout == ""

    parts = cmdout.split
    pcpu = parts[0].strip.to_f
    pmem = parts[1].strip.to_f
    rsz = parts[2].strip.to_f * 1024
    vsz = parts[3].strip.to_f * 1024
    uptime = parts[4].strip.to_f

    labels = {:cluster => @args.cluster_name, :hostname => @args.gluster_host}
    yield Crometheus::Sample.new(pcpu, labels: labels, suffix: "cpu_percentage")
    yield Crometheus::Sample.new(pmem, labels: labels, suffix: "memory_percentage")
    yield Crometheus::Sample.new(rsz, labels: labels, suffix: "resident_memory_bytes")
    yield Crometheus::Sample.new(vsz, labels: labels, suffix: "virtual_memory_bytes")
    yield Crometheus::Sample.new(uptime, labels: labels, suffix: "uptime_seconds")
  end
end
