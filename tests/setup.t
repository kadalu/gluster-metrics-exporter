# -*- mode: ruby -*-
USE_REMOTE_PLUGIN "docker"
nodes = ["gserver1", "gserver2", "gserver3"]

# Start three or N storage nodes(Containers)
USE_NODE "local"
nodes.each do |node|
  USE_NODE "local"
  RUN "docker stop #{node}"
  RUN "docker rm #{node}"
end

RUN "docker network rm g1"
TEST "docker network create g1"

nodes.each do |node|
  USE_NODE "local"
  TEST "docker run -d -v /sys/fs/cgroup/:/sys/fs/cgroup:ro --privileged --name #{node} --hostname #{node} --network g1 kadalu/gluster-node"
end
