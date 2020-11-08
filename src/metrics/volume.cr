require "crometheus"

require "./metric"
require "../metrics_server"
require "./gluster_commands"

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
    volumes = GlusterCommands.volume_info(@args)
    volume_status = GlusterCommands.volume_status(volumes, @args)

    grouped_data = volumes.group_by do |volume|
      [volume.state, volume.type]
    end

    # Group the data as {state, type} and export the count for each group
    grouped_data.each do |key, value|
      yield Crometheus::Sample.new(
        value.size.to_f,
        labels: {:cluster => @args.cluster_name, :state => key[0], :type => key[1]},
        suffix: "count"
      )
    end

    volumes.each do |volume|
      # TODO: Merge Volume Status to show meaningful health
      state = volume.state == "Started" ? 1.0 : 0.0
      yield Crometheus::Sample.new(
        state,
        labels: {:cluster => @args.cluster_name, :state => volume.state},
        suffix: "state"
      )

      yield Crometheus::Sample.new(
        volume.distribute_count.to_f,
        labels: {:cluster => @args.cluster_name, :name => volume.name},
        suffix: "distribute_count"
      )

      yield Crometheus::Sample.new(
        volume.brick_count.to_f,
        labels: {:cluster => @args.cluster_name, :name => volume.name},
        suffix: "brick_count"
      )

      yield Crometheus::Sample.new(
        volume.snapshot_count.to_f,
        labels: {:cluster => @args.cluster_name, :name => volume.name},
        suffix: "snapshot_count"
      )

      yield Crometheus::Sample.new(
        volume.replica_count.to_f,
        labels: {:cluster => @args.cluster_name, :name => volume.name},
        suffix: "replica_count"
      )

      yield Crometheus::Sample.new(
        volume.arbiter_count.to_f,
        labels: {:cluster => @args.cluster_name, :name => volume.name},
        suffix: "arbiter_count"
      )

      yield Crometheus::Sample.new(
        volume.disperse_count.to_f,
        labels: {:cluster => @args.cluster_name, :name => volume.name},
        suffix: "disperse_count"
      )
    end

    volume_status.each do |volume|
      yield Crometheus::Sample.new(
        volume.subvols.size.to_f,
        labels: {:cluster => @args.cluster_name, :name => volume.name},
        suffix: "subvol_count"
      )

      # volume_health (0 - Not Started, 1 - Down, 2 - Degraded, 3 - Partial, 4 - Up)
      yield Crometheus::Sample.new(
        health_to_value(volume.state, volume.health),
        labels: {:cluster => @args.cluster_name,
                 :name => volume.name,
                 :type => volume.type,
                 :state => volume.state},
        suffix: "health"
      )

      yield Crometheus::Sample.new(
        volume.size_used,
        labels: {:cluster => @args.cluster_name,
                 :name => volume.name,
                 :type => volume.type,
                 :state => volume.state},
        suffix: "capacity_used_bytes"
      )

      yield Crometheus::Sample.new(
        volume.size_free,
        labels: {:cluster => @args.cluster_name,
                 :name => volume.name,
                 :type => volume.type,
                 :state => volume.state},
        suffix: "capacity_free_bytes"
      )

      yield Crometheus::Sample.new(
        volume.size_total,
        labels: {:cluster => @args.cluster_name,
                 :name => volume.name,
                 :type => volume.type,
                 :state => volume.state},
        suffix: "capacity_bytes"
      )

      yield Crometheus::Sample.new(
        volume.inodes_used,
        labels: {:cluster => @args.cluster_name,
                 :name => volume.name,
                 :type => volume.type,
                 :state => volume.state},
        suffix: "inodes_used_count"
      )

      yield Crometheus::Sample.new(
        volume.inodes_free,
        labels: {:cluster => @args.cluster_name,
                 :name => volume.name,
                 :type => volume.type,
                 :state => volume.state},
        suffix: "inodes_free_count"
      )

      yield Crometheus::Sample.new(
        volume.inodes_total,
        labels: {:cluster => @args.cluster_name,
                 :name => volume.name,
                 :type => volume.type,
                 :state => volume.state},
        suffix: "inodes_count"
      )

      volume.subvols.each_with_index do |subvol, sidx|
        yield Crometheus::Sample.new(
          subvol.bricks.size.to_f,
          labels: {:cluster => @args.cluster_name, :name => volume.name, :subvol_index => "#{sidx}"},
          suffix: "subvol_brick_count"
        )

        # volume_subvol_health (0 - Not Started, 1 - Down, 2 - Degraded, 3 - Partial, 4 - Up)
        yield Crometheus::Sample.new(
          health_to_value(volume.state, subvol.health),
          labels: {:cluster => @args.cluster_name,
                   :name => volume.name,
                   :state => volume.state,
                   :type => subvol.type,
                   :subvol_index => "#{sidx}"},
          suffix: "subvol_health"
        )

        yield Crometheus::Sample.new(
          subvol.size_used,
          labels: {:cluster => @args.cluster_name,
                   :name => volume.name,
                   :type => volume.type,
                   :state => volume.state,
                   :subvol_index => "#{sidx}"},
          suffix: "subvol_capacity_used_bytes"
        )

        yield Crometheus::Sample.new(
          subvol.size_free,
          labels: {:cluster => @args.cluster_name,
                   :name => volume.name,
                   :type => volume.type,
                   :state => volume.state,
                   :subvol_index => "#{sidx}"},
          suffix: "subvol_capacity_free_bytes"
        )

        yield Crometheus::Sample.new(
          subvol.size_total,
          labels: {:cluster => @args.cluster_name,
                   :name => volume.name,
                   :type => volume.type,
                   :state => volume.state,
                   :subvol_index => "#{sidx}"},
          suffix: "subvol_capacity_bytes"
        )

        yield Crometheus::Sample.new(
          subvol.inodes_used,
          labels: {:cluster => @args.cluster_name,
                   :name => volume.name,
                   :type => volume.type,
                   :state => volume.state,
                   :subvol_index => "#{sidx}"},
          suffix: "subvol_inodes_used_count"
        )

        yield Crometheus::Sample.new(
          subvol.inodes_free,
          labels: {:cluster => @args.cluster_name,
                   :name => volume.name,
                   :type => volume.type,
                   :state => volume.state,
                   :subvol_index => "#{sidx}"},
          suffix: "subvol_inodes_free_count"
        )

        yield Crometheus::Sample.new(
          subvol.inodes_total,
          labels: {:cluster => @args.cluster_name,
                   :name => volume.name,
                   :type => volume.type,
                   :state => volume.state,
                   :subvol_index => "#{sidx}"},
          suffix: "subvol_inodes_count"
        )

        subvol.bricks.each do |brick|
          # Report Brick Health only if started
          if volume.state == "Started"
            yield Crometheus::Sample.new(
              brick.state,
              labels: {:cluster => @args.cluster_name,
                       :name => volume.name,
                       :type => volume.type,
                       :state => volume.state,
                       :hostname => brick.node.hostname,
                       :brick_path => brick.path,
                       :subvol_index => "#{sidx}"},
              suffix: "brick_health"
            )
          end

          yield Crometheus::Sample.new(
            brick.size_used,
            labels: {:cluster => @args.cluster_name,
                     :name => volume.name,
                     :type => volume.type,
                     :state => volume.state,
                     :hostname => brick.node.hostname,
                     :brick_path => brick.path,
                     :subvol_index => "#{sidx}"},
            suffix: "brick_capacity_used_bytes"
          )

          yield Crometheus::Sample.new(
            brick.size_free,
            labels: {:cluster => @args.cluster_name,
                     :name => volume.name,
                     :type => volume.type,
                     :state => volume.state,
                     :hostname => brick.node.hostname,
                     :brick_path => brick.path,
                     :subvol_index => "#{sidx}"},
            suffix: "brick_capacity_free_bytes"
          )

          yield Crometheus::Sample.new(
            brick.size_total,
            labels: {:cluster => @args.cluster_name,
                     :name => volume.name,
                     :type => volume.type,
                     :state => volume.state,
                     :hostname => brick.node.hostname,
                     :brick_path => brick.path,
                     :subvol_index => "#{sidx}"},
            suffix: "brick_capacity_bytes"
          )

          yield Crometheus::Sample.new(
            brick.inodes_used,
            labels: {:cluster => @args.cluster_name,
                     :name => volume.name,
                     :type => volume.type,
                     :state => volume.state,
                     :hostname => brick.node.hostname,
                     :brick_path => brick.path,
                     :subvol_index => "#{sidx}"},
            suffix: "brick_inodes_used_count"
          )

          yield Crometheus::Sample.new(
            brick.inodes_free,
            labels: {:cluster => @args.cluster_name,
                     :name => volume.name,
                     :type => volume.type,
                     :state => volume.state,
                     :hostname => brick.node.hostname,
                     :brick_path => brick.path,
                     :subvol_index => "#{sidx}"},
            suffix: "brick_inodes_free_count"
          )

          yield Crometheus::Sample.new(
            brick.inodes_total,
            labels: {:cluster => @args.cluster_name,
                     :name => volume.name,
                     :type => volume.type,
                     :state => volume.state,
                     :hostname => brick.node.hostname,
                     :brick_path => brick.path,
                     :subvol_index => "#{sidx}"},
            suffix: "brick_inodes_count"
          )
        end
      end
    end
  end

  def health_to_value(state, health)
    return 0.0 if state != "Started"

    case health
    when HEALTH_DOWN
      1.0
    when HEALTH_DEGRADED
      2.0
    when HEALTH_PARTIAL
      3.0
    when HEALTH_UP
      4.0
    else
      0.0
    end
  end
end
