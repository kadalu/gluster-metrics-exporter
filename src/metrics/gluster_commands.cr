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

    peers = [] of Peer
    prs.each do |pr|
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

      peers << peer
    end

    peers
  end

  def self.brick_status(args)
    # TODO: Volume filter
    rc, resp = execute_cmd(args.gluster_executable_path,
                           ["volume", "status", "all", "detail", "--xml"])
    # TODO: Log error if rc != 0
    return [] of Brick if rc != 0

    document = XML.parse(resp)

    bricks_data = document.xpath_nodes("//volStatus/volumes/volume/node")
    bricks = [] of Brick
    bricks_data.each do |brk|
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

      bricks << brick
    end

    bricks
  end

  def self.volume_info(args)
    rc, resp = execute_cmd(args.gluster_executable_path,
                           ["volume", "info", "--xml"])
    # TODO: Log error if rc != 0
    return [] of Volume if rc != 0

    document = XML.parse(resp)

    vols = document.xpath_nodes("//volume")

    volumes = [] of Volume
    vols.each do |vol|
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

      volumes << volume
    end

    volumes
  end

  private def self.update_brick_status(volumes, bricks_status)
    tmp_brick_status = {} of String => Brick
    bricks_status.each do |brick|
      tmp_brick_status["#{brick.node.hostname}:#{brick.path}"] = brick
    end

    outvolumes = [] of Volume
    volumes.each do |volume|
      volume.bricks.each do |brick|
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
      end
    end

    volumes
  end

  private def self.group_subvols(volumes)
    volumes.each_with_index do |volume, idx|
      subvol_type = volume.type.split(" ")[-1]
      subvol_bricks_count = volume.bricks.size / volume.distribute_count

      (0...volume.distribute_count).each do |sidx|
        subvol = Subvolume.new
        subvol.type = subvol_type
        subvol.replica_count = volume.replica_count
        subvol.disperse_count = volume.disperse_count
        subvol.disperse_redundancy_count = volume.disperse_redundancy_count

        volume.subvols << subvol
      end

      sidx = 0
      volume.bricks.each_slice(subvol_bricks_count.to_i) do |grp|
        volume.subvols[sidx].bricks = grp
        sidx += 1
      end
    end

    volumes
  end

  private def self.subvol_health(subvol)
    up_bricks = 0
    subvol.bricks.each do |brick|
      up_bricks += 1 if brick.state == 1.0
    end

    health = HEALTH_UP
    if subvol.bricks.size != up_bricks
      health = HEALTH_DOWN
      if subvol.type == TYPE_REPLICATE && up_bricks >= (subvol.replica_count/2).ceil
        health = HEALTH_PARTIAL
      end
      # If down bricks are less than or equal to redudancy count
      # then Volume is UP but some bricks are down
      if subvol.type == TYPE_DISPERSE && (subvol.bricks.size - up_bricks) <= subvol.disperse_redundancy_count
        health = HEALTH_PARTIAL
      end
    end

    health
  end

  private def self.update_volume_health(volumes)
    volumes.each do |volume|
      next if volume.state != STATE_STARTED

      volume.health = HEALTH_UP
      up_subvols = 0

      volume.subvols.each do |subvol|
        subvol.health = subvol_health(subvol)
        if subvol.health == HEALTH_DOWN
          volume.health = HEALTH_DEGRADED
        end
        if subvol.health == HEALTH_PARTIAL && volume.health != HEALTH_DEGRADED
          volume.health = subvol.health
        end

        if subvol.health != HEALTH_DOWN
          up_subvols += 1
        end
      end

      if up_subvols == 0
        volume.health = HEALTH_DOWN
      end
    end

    volumes
  end

  private def self.update_volume_utilization(volumes)
    volumes.each do |volume|
      volume.subvols.each do |subvol|
        effective_capacity_used = 0
        effective_capacity_total = 0
        effective_inodes_used = 0
        effective_inodes_total = 0

        subvol.bricks.each do |brick|
          next if brick.type == "Arbiter"

          if brick.size_used >= effective_capacity_used
            effective_capacity_used = brick.size_used
          end

          if effective_capacity_total == 0 ||
             (brick.size_total <= effective_capacity_total &&
              brick.size_total > 0)
            effective_capacity_total = brick.size_total
          end

          if brick.inodes_used >= effective_inodes_used
            effective_inodes_used = brick.inodes_used
          end

          if effective_inodes_total == 0 ||
             (brick.inodes_total <= effective_inodes_total &&
              brick.inodes_total > 0)
            effective_inodes_total = brick.inodes_total
          end
        end

        if subvol.type == TYPE_DISPERSE
          # Subvol Size = Sum of size of Data bricks
          effective_capacity_used = effective_capacity_used * (
            subvol.disperse_count - subvol.disperse_redundancy_count)

          effective_capacity_total = effective_capacity_total * (
            subvol.disperse_count - subvol.disperse_redundancy_count)

          effective_inodes_used = effective_inodes_used * (
            subvol.disperse_count - subvol.disperse_redundancy_count)

          effective_inodes_total = effective_inodes_total * (
            subvol.disperse_count - subvol.disperse_redundancy_count)
        end
        volume.size_total += effective_capacity_total
        volume.size_used += effective_capacity_used
        volume.size_free = volume.size_total - volume.size_used
        volume.inodes_total += effective_inodes_total
        volume.inodes_used += effective_inodes_used
        volume.inodes_free = volume.inodes_total - volume.inodes_used
      end
    end

    volumes
  end

  def self.volume_status(volinfo, args)
    bricks_data = brick_status(args)
    volumes = update_brick_status(volinfo, bricks_data)
    volumes = group_subvols(volumes)
    volumes = update_volume_utilization(volumes)
    update_volume_health(volumes)
  end
end
