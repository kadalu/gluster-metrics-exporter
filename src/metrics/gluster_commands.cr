require "xml"

require "./metric"

HEALTH_UP = "up"
HEALTH_DOWN = "down"
HEALTH_PARTIAL = "partial"
HEALTH_DEGRADED = "degraded"

STATE_CREATED = "Created"
STATE_STARTED = "Started"
STATE_STOPPED = "Stopped"

TYPE_REPLICATE = "Replicate"
TYPE_DISPERSE = "Disperse"

module GlusterCommands
  struct Node
    property id = "",
             hostname = ""
  end

  struct Brick
    property node = Node.new,
             path = "",
             type = "",
             state = 0.0,
             pid = 0.0,
             size_total = 0.0,
             size_free = 0.0,
             inodes_total = 0.0,
             inodes_free = 0.0,
             size_used = 0.0,
             inodes_used = 0.0,
             device = "",
             block_size = 0.0,
             fs_name = "",
             mnt_options = ""
  end

  struct Subvolume
    property type = "",
             health = "",
             replica_count = 0,
             disperse_count = 0,
             disperse_redundancy_count = 0,
             arbiter_count = 0,
             size_total = 0.0,
             size_free = 0.0,
             inodes_total = 0.0,
             inodes_free = 0.0,
             size_used = 0.0,
             inodes_used = 0.0,
             up_bricks = 0,
             bricks = [] of Brick
  end

  struct Volume
    property name = "",
             id = "",
             state = "",
             snapshot_count = 0,
             brick_count = 0,
             distribute_count = 0,
             replica_count = 0,
             arbiter_count = 0,
             disperse_count = 0,
             disperse_redundancy_count = 0,
             type = "",
             health = "",
             transport = "",
             size_total = 0.0,
             size_free = 0.0,
             inodes_total = 0.0,
             inodes_free = 0.0,
             size_used = 0.0,
             inodes_used = 0.0,
             up_subvols = 0,
             subvols = [] of Subvolume,
             bricks = [] of Brick,
             options = {} of String => String
  end

  struct Peer
    property id = "", hostname = "", state = 0.0
  end

  def self.pool_list(args)
    rc, resp = execute_cmd(args.gluster_executable_path,
                           ["pool", "list", "--xml"])
    # TODO: Log error if rc != 0
    return [] of Peer if rc != 0

    document = XML.parse(resp)

    prs = document.xpath_nodes("//peerStatus/peer")

    prs.map do |pr|
      peer = Peer.new
      pr.children.each do |ele|
        case ele.name
        when "uuid"
          peer.id = ele.content.strip
        when "hostname"
          peer.hostname = ele.content.strip
        when "connected"
          peer.state = ele.content.strip.to_f

        end
      end

      peer
    end
  end

  def self.brick_status(args)
    # TODO: Volume filter
    rc, resp = execute_cmd(args.gluster_executable_path,
                           ["volume", "status", "all", "detail", "--xml"])
    # TODO: Log error if rc != 0
    return [] of Brick if rc != 0

    document = XML.parse(resp)

    bricks_data = document.xpath_nodes("//volStatus/volumes/volume/node")

    bricks_data.map do |brk|
      brick = Brick.new
      brk.children.each do |ele|
        case ele.name
        when "hostname"
          brick.node.hostname = ele.content.strip
        when "path"
          brick.path = ele.content.strip
        when "peerid"
          brick.node.id = ele.content.strip
        when "status"
          brick.state = ele.content.strip.to_f
        when "pid"
          brick.pid = ele.content.strip.to_f
        when "sizeTotal"
          brick.size_total = ele.content.strip.to_f
        when "sizeFree"
          brick.size_free = ele.content.strip.to_f
        when "inodesTotal"
          brick.inodes_total = ele.content.strip.to_f
        when "inodesFree"
          brick.inodes_free = ele.content.strip.to_f
        when "device"
          brick.device = ele.content.strip
        when "blockSize"
          brick.block_size = ele.content.strip.to_f
        when "fsName"
          brick.fs_name = ele.content.strip
        when "mntOptions"
          brick.mnt_options = ele.content.strip
        end
      end

      brick.size_used = brick.size_total - brick.size_free
      brick.inodes_used = brick.inodes_total - brick.inodes_free

      brick
    end
  end

  def self.volume_info(args)
    rc, resp = execute_cmd(args.gluster_executable_path,
                           ["volume", "info", "--xml"])
    # TODO: Log error if rc != 0
    return [] of Volume if rc != 0

    document = XML.parse(resp)

    vols = document.xpath_nodes("//volume")

    vols.map do |vol|
      volume = Volume.new
      vol.children.each do |ele|
        case ele.name
        when "name"
          volume.name = ele.content.strip
        when "id"
          volume.id = ele.content.strip
        when "statusStr"
          volume.state = ele.content.strip
        when "typeStr"
          volume.type = ele.content.strip
        when "transport"
          volume.transport = "tcp" if ele.content.strip == "0"
        when "snapshotCount"
          volume.snapshot_count = ele.content.strip.to_i
        when "brickCount"
          volume.brick_count = ele.content.strip.to_i
        when "distCount"
          volume.distribute_count = ele.content.strip.to_i
        when "replicaCount"
          volume.replica_count = ele.content.strip.to_i
        when "arbiterCount"
          volume.arbiter_count = ele.content.strip.to_i
        when "disperseCount"
          volume.disperse_count = ele.content.strip.to_i
        when "redundancyCount"
          volume.disperse_redundancy_count = ele.content.strip.to_i
        else
          nil
        end
      end

      brks = vol.xpath_nodes("//brick")
      brks.each do |brk|
        brick = Brick.new
        brk.children.each do |bele|
          case bele.name
          when "name"
            parts = bele.content.strip.split(":")
            brick.node.hostname = parts[0 ... -1].join(":")
            brick.path = parts[-1]
          when "hostUuid"
            brick.node.id = bele.content.strip
          when "isArbiter"
            brick.type = bele.content.strip == '1' ? "Arbiter" : "Brick"
          end
        end
        volume.bricks << brick
      end

      opts = vol.xpath_nodes("//option")
      opts.each do |opt|
        option = Hash(String, String).new
        optname = ""
        optvalue = ""
        opt.children.each do |oele|
          case oele.name
          when "name"
            optname = oele.content.strip
          when "value"
            optvalue = oele.content.strip
          end
        end
        volume.options[optname] = optvalue
      end

      volume
    end
  end

  private def self.update_brick_status(volumes, bricks_status)
    # Update each brick's status from Volume status output

    # Create hashmap of Bricks data so that it
    # helps to lookup later.
    tmp_brick_status = {} of String => Brick
    bricks_status.each do |brick|
      tmp_brick_status["#{brick.node.hostname}:#{brick.path}"] = brick
    end

    volumes.map do |volume|
      volume.subvols = volume.subvols.map do |subvol|
        subvol.bricks = volume.bricks.map do |brick|
          # Update brick status info if volume status output
          # contains respective brick info. Sometimes volume
          # status skips brick entries if glusterd of respective
          # node is not reachable or down(Offline).
          data = tmp_brick_status["#{brick.node.hostname}:#{brick.path}"]?
          if !data.nil?
            brick.state = data.state
            brick.pid = data.pid
            brick.size_total = data.size_total
            brick.size_free = data.size_free
            brick.size_used = data.size_used
            brick.inodes_total = data.inodes_total
            brick.inodes_free = data.inodes_free
            brick.inodes_used = data.inodes_used
            brick.device = data.device
            brick.block_size = data.block_size
            brick.mnt_options = data.mnt_options
            brick.fs_name = data.fs_name
          end

          brick
        end

        subvol
      end

      volume
    end
  end

  # Group bricks into subvolumes
  private def self.group_subvols(volumes)
    volumes.map do |volume|
      # "Distributed Replicate" will become "Replicate"
      subvol_type = volume.type.split(" ")[-1]
      subvol_bricks_count = volume.bricks.size / volume.distribute_count

      # Divide the bricks list as subvolumes
      subvol_bricks = [] of Array(Brick)
      volume.bricks.each_slice(subvol_bricks_count.to_i) do |grp|
        subvol_bricks << grp
      end

      volume.subvols = (0...volume.distribute_count).map do |sidx|
        subvol = Subvolume.new
        subvol.type = subvol_type
        subvol.replica_count = volume.replica_count
        subvol.disperse_count = volume.disperse_count
        subvol.disperse_redundancy_count = volume.disperse_redundancy_count
        subvol.bricks = subvol_bricks[sidx]

        subvol
      end

      volume
    end
  end

  private def self.update_subvol_health(subvol)
    subvol.up_bricks = 0
    subvol.bricks.each do |brick|
      subvol.up_bricks += 1 if brick.state == 1.0
    end

    subvol.health = HEALTH_UP
    if subvol.bricks.size != subvol.up_bricks
      subvol.health = HEALTH_DOWN
      if subvol.type == TYPE_REPLICATE && subvol.up_bricks >= (subvol.replica_count/2).ceil
        subvol.health = HEALTH_PARTIAL
      end
      # If down bricks are less than or equal to redudancy count
      # then Volume is UP but some bricks are down
      if subvol.type == TYPE_DISPERSE && (subvol.bricks.size - subvol.up_bricks) <= subvol.disperse_redundancy_count
        subvol.health = HEALTH_PARTIAL
      end
    end

    subvol
  end

  # Update Volume health based on subvolume health
  private def self.update_volume_health(volumes)
    volumes.map do |volume|
      if volume.state == STATE_STARTED
        volume.health = HEALTH_UP
        volume.up_subvols = 0

        volume.subvols = volume.subvols.map do |subvol|
          # Update Subvolume health based on bricks health
          subvol = update_subvol_health(subvol)

          # One subvol down means the Volume is degraded
          if subvol.health == HEALTH_DOWN
            volume.health = HEALTH_DEGRADED
          end

          # If Volume is not yet degraded, then it
          # may be same as subvolume health
          if subvol.health == HEALTH_PARTIAL && volume.health != HEALTH_DEGRADED
            volume.health = subvol.health
          end

          if subvol.health != HEALTH_DOWN
            volume.up_subvols += 1
          end

          subvol
        end

        if volume.up_subvols == 0
          volume.health = HEALTH_DOWN
        end
      end

      volume
    end
  end

  private def self.update_volume_utilization(volumes)
    volumes.map do |volume|
      volume.subvols = volume.subvols.map do |subvol|
        subvol.size_used = 0.0
        subvol.size_total = 0.0
        subvol.inodes_used = 0.0
        subvol.inodes_total = 0.0

        # Subvolume utilization
        subvol.bricks.each do |brick|
          next if brick.type == "Arbiter"

          subvol.size_used = brick.size_used if brick.size_used >= subvol.size_used

          if subvol.size_total == 0 ||
             (brick.size_total <= subvol.size_total &&
              brick.size_total > 0)
            subvol.size_total = brick.size_total
          end

          subvol.inodes_used = brick.inodes_used if brick.inodes_used >= subvol.inodes_used

          if subvol.inodes_total == 0 ||
             (brick.inodes_total <= subvol.inodes_total &&
              brick.inodes_total > 0)
            subvol.inodes_total = brick.inodes_total
          end
        end

        # Subvol Size = Sum of size of Data bricks
        if subvol.type == TYPE_DISPERSE
          subvol.size_used = subvol.size_used * (
            subvol.disperse_count - subvol.disperse_redundancy_count)

          subvol.size_total = subvol.size_total * (
            subvol.disperse_count - subvol.disperse_redundancy_count)

          subvol.inodes_used = subvol.inodes_used * (
            subvol.disperse_count - subvol.disperse_redundancy_count)

          subvol.inodes_total = subvol.inodes_total * (
            subvol.disperse_count - subvol.disperse_redundancy_count)
        end

        # Aggregated volume utilization
        volume.size_total += subvol.size_total
        volume.size_used += subvol.size_used
        volume.size_free = volume.size_total - volume.size_used
        volume.inodes_total += subvol.inodes_total
        volume.inodes_used += subvol.inodes_used
        volume.inodes_free = volume.inodes_total - volume.inodes_used

        subvol
      end

      volume
    end
  end

  def self.volume_status(volinfo, args)
    bricks_data = brick_status(args)
    volumes = group_subvols(volinfo)
    volumes = update_brick_status(volumes, bricks_data)
    volumes = update_volume_utilization(volumes)
    update_volume_health(volumes)
  end
end
