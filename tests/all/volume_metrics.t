# -*- mode: ruby -*-
load "#{File.dirname(__FILE__)}/../reset.t"

USE_REMOTE_PLUGIN "docker"

nodes = ["gserver1", "gserver2", "gserver3"]

nodes.each do |node|
  USE_NODE node

  TEST "systemctl start glusterd"
  puts TEST "systemctl status glusterd"
  TEST "systemctl start gluster-metrics-exporter"
  puts TEST "systemctl status gluster-metrics-exporter"

  TEST "mkdir -p /exports/vol1"
end

USE_NODE nodes[0]
TEST "gluster peer probe #{nodes[1]}"
TEST "gluster peer probe #{nodes[2]}"
TEST "gluster volume create vol1 replica 3 #{nodes[0]}:/exports/vol1/s1 #{nodes[1]}:/exports/vol1/s2 #{nodes[2]}:/exports/vol1/s3 force"
TEST "gluster volume start vol1"
puts TEST "curl http://localhost:9713/metrics"
puts TEST "curl http://localhost:9713/metrics.json"

nodes.each do |node|
  USE_NODE node
  puts TEST "cat /var/log/gluster-metrics-exporter/exporter.log"
end
