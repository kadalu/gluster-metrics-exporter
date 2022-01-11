# -*- mode: ruby -*-

USE_REMOTE_PLUGIN "docker"
nodes = ["gserver1", "gserver2", "gserver3"]

nodes.each do |node|
  USE_NODE node
  RUN "systemctl stop glusterd"
  RUN "systemctl disable glusterd"
  RUN "systemctl stop gluster-metrics-exporter"
  RUN "systemctl disable gluster-metrics-exporter"
  RUN "rm -rf /var/lib/glusterd"
  RUN "rm -rf /var/log/gluster"
  RUN "rm -rf /var/log/gluster-metrics-exporter"
end
