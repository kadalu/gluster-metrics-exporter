module GlusterMetricsExporter
  Crometheus.alias VolumeCountGauge = Crometheus::Gauge[:type, :state]
  Crometheus.alias VolumeGauge = Crometheus::Gauge[:type, :state, :name]
  Crometheus.alias SubvolumeGauge = Crometheus::Gauge[:volume_type, :volume_state, :volume_name, :subvol_index]
  Crometheus.alias BrickGauge = Crometheus::Gauge[:volume_type, :volume_state, :volume_name, :subvol_index, :hostname, :path]

  @@volume_count = VolumeCountGauge.new(:volume_count, "Number of Volumes")
  @@dist_count = VolumeGauge.new(:volume_distribute_count, "Distribute Count")
  @@brick_count = VolumeGauge.new(:volume_brick_count, "Number of bricks")
  @@snap_count = VolumeGauge.new(:volume_snapshot_count, "Number of Snapshots")
  @@replica_count = VolumeGauge.new(:volume_replica_count, "Replica Count")
  @@arbiter_count = VolumeGauge.new(:volume_arbiter_count, "Arbiter Count")
  @@disperse_count = VolumeGauge.new(:volume_disperse_count, "Disperse Count")
  @@subvol_count = VolumeGauge.new(:volume_subvol_count, "Number of Subvolumes")
  @@health = VolumeGauge.new(:volume_health, "Volume Health")
  @@up_subvols = VolumeGauge.new(:volume_up_subvols, "Number of Up Subvolumes")
  @@size_used = VolumeGauge.new(:volume_capacity_used_bytes, "Capacity Used Bytes")
  @@size_free = VolumeGauge.new(:volume_capacity_free_bytes, "Capacity Free Bytes")
  @@size_total = VolumeGauge.new(:volume_capacity_bytes, "Capacity Total Bytes")
  @@inodes_used = VolumeGauge.new(:volume_inodes_used_count, "Inodes Used Count")
  @@inodes_free = VolumeGauge.new(:volume_inodes_free_count, "Inodes Free Count")
  @@inodes_total = VolumeGauge.new(:volume_inodes_count, "Inodes Total Count")

  @@subvol_brick_count = SubvolumeGauge.new(:subvol_brick_count, "Subvolume Bricks Count")
  @@subvol_health = SubvolumeGauge.new(:subvol_health, "Subvolume Health")
  @@subvol_up_bricks = SubvolumeGauge.new(:subvol_up_bricks, "Subvolume Up Bricks")
  @@subvol_size_used = SubvolumeGauge.new(:subvol_capacity_used_bytes, "Subvolume Capacity Used Bytes")
  @@subvol_size_free = SubvolumeGauge.new(:subvol_capacity_free_bytes, "Subvolume Capacity Free Bytes")
  @@subvol_size_total = SubvolumeGauge.new(:subvol_capacity_bytes, "Subvolume Capacity Total Bytes")
  @@subvol_inodes_used = SubvolumeGauge.new(:subvol_inodes_used_count, "Subvolume Inodes Used Count")
  @@subvol_inodes_free = SubvolumeGauge.new(:subvol_inodes_free_count, "Subvolume Inodes Free Count")
  @@subvol_inodes_total = SubvolumeGauge.new(:subvol_inodes_count, "Subvolume Inodes Total Count")

  @@brick_health = BrickGauge.new(:brick_health, "Brick Health")
  @@brick_size_used = BrickGauge.new(:brick_capacity_used_bytes, "Brick Capacity Used Bytes")
  @@brick_size_free = BrickGauge.new(:brick_capacity_free_bytes, "Brick Capacity Free Bytes")
  @@brick_size_total = BrickGauge.new(:brick_capacity_bytes, "Brick Capacity Total Bytes")
  @@brick_inodes_used = BrickGauge.new(:brick_inodes_used_count, "Brick Inodes Used Count")
  @@brick_inodes_free = BrickGauge.new(:brick_inodes_free_count, "Brick Inodes Free Count")
  @@brick_inodes_total = BrickGauge.new(:brick_inodes_count, "Brick Inodes Total Count")

  def self.clear_volume_metrics
    @@volume_count.clear
    @@dist_count.clear
    @@brick_count.clear
    @@snap_count.clear
    @@replica_count.clear
    @@arbiter_count.clear
    @@disperse_count.clear
    @@subvol_count.clear
    @@health.clear
    @@up_subvols.clear
    @@size_used.clear
    @@size_free.clear
    @@size_total.clear
    @@inodes_used.clear
    @@inodes_free.clear
    @@inodes_total.clear
    @@subvol_brick_count.clear
    @@subvol_health.clear
    @@subvol_up_bricks.clear
    @@subvol_size_used.clear
    @@subvol_size_free.clear
    @@subvol_size_total.clear
    @@subvol_inodes_used.clear
    @@subvol_inodes_free.clear
    @@subvol_inodes_total.clear
    @@brick_health.clear
    @@brick_size_used.clear
    @@brick_size_free.clear
    @@brick_size_total.clear
    @@brick_inodes_used.clear
    @@brick_inodes_free.clear
    @@brick_inodes_total.clear
  end

  handle_metrics(["volume", "volume_status"]) do |metrics_data|
    # Reset all Metrics to avoid stale data. Careful if
    # counter type is used
    clear_volume_metrics

    # If Volume Metrics are not enabled
    next if !@@config.enabled?("volume")

    grouped_data = metrics_data.volumes.group_by do |vol|
      [vol.type, vol.state]
    end

    grouped_data.each do |data|
      @@volume_count[type: data[0][0], state: data[0][1]].set data[1].size
    end

    metrics_data.volumes.each do |volume|
      volume_labels = {
        type:  volume.type,
        state: volume.state,
        name:  volume.name,
      }

      @@dist_count[**volume_labels].set(volume.distribute_count)
      @@brick_count[**volume_labels].set(volume.brick_count)
      @@snap_count[**volume_labels].set(volume.snapshot_count)
      @@replica_count[**volume_labels].set(volume.replica_count)
      @@arbiter_count[**volume_labels].set(volume.arbiter_count)
      @@disperse_count[**volume_labels].set(volume.disperse_count)
      @@subvol_count[**volume_labels].set(volume.subvols.size)

      if volume.state == "Started" && @@config.enabled?("volume_status")
        # volume_health (0 - Not Started, 1 - Down,
        # 2 - Degraded, 3 - Partial, 4 - Up)
        @@health[**volume_labels].set(health_to_value(volume.state, volume.health))
        @@up_subvols[**volume_labels].set(volume.up_subvols)
        @@size_used[**volume_labels].set(volume.size_used)
        @@size_free[**volume_labels].set(volume.size_free)
        @@size_total[**volume_labels].set(volume.size_total)
        @@inodes_used[**volume_labels].set(volume.inodes_used)
        @@inodes_free[**volume_labels].set(volume.inodes_free)
        @@inodes_total[**volume_labels].set(volume.inodes_total)
      end
      volume.subvols.each_with_index do |subvol, sidx|
        subvol_labels = {
          volume_type:  volume.type,
          volume_state: volume.state,
          volume_name:  volume.name,
          subvol_index: "#{sidx}",
        }

        @@subvol_brick_count[**subvol_labels].set(subvol.bricks.size)

        if volume.state == "Started" && @@config.enabled?("volume_status")
          # volume_subvol_health (0 - Not Started, 1 - Down,
          # 2 - Degraded, 3 - Partial, 4 - Up)
          @@subvol_health[**subvol_labels].set(health_to_value(volume.state, subvol.health))
          @@subvol_up_bricks[**subvol_labels].set(subvol.up_bricks)
          @@subvol_size_used[**subvol_labels].set(subvol.size_used)
          @@subvol_size_free[**subvol_labels].set(subvol.size_free)
          @@subvol_size_total[**subvol_labels].set(subvol.size_total)
          @@subvol_inodes_used[**subvol_labels].set(subvol.inodes_used)
          @@subvol_inodes_free[**subvol_labels].set(subvol.inodes_free)
          @@subvol_inodes_total[**subvol_labels].set(subvol.inodes_total)
        end

        subvol.bricks.each do |brick|
          brick_labels = {
            volume_name:  volume.name,
            volume_type:  volume.type,
            volume_state: volume.state,
            hostname:     brick.node.hostname,
            path:         brick.path,
            subvol_index: "#{sidx}",
          }
          # Report Brick Health only if started
          if volume.state == "Started" && @@config.enabled?("volume_status")
            @@brick_health[**brick_labels].set(brick.state ? 1 : 0)

            @@brick_size_used[**brick_labels].set(brick.size_used)
            @@brick_size_free[**brick_labels].set(brick.size_free)
            @@brick_size_total[**brick_labels].set(brick.size_total)
            @@brick_inodes_used[**brick_labels].set(brick.inodes_used)
            @@brick_inodes_free[**brick_labels].set(brick.inodes_free)
            @@brick_inodes_total[**brick_labels].set(brick.inodes_total)
          end
        end
      end
    end
  end

  def self.health_to_value(state, health)
    return 0.0 if state != "Started"

    case health
    when GlusterCLI::HEALTH_DOWN
      1.0
    when GlusterCLI::HEALTH_DEGRADED
      2.0
    when GlusterCLI::HEALTH_PARTIAL
      3.0
    when GlusterCLI::HEALTH_UP
      4.0
    else
      0.0
    end
  end
end
