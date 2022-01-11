# -*- mode: ruby -*-

USE_REMOTE_PLUGIN "docker"
nodes = ["gserver1", "gserver2", "gserver3"]

# Static build Kadalu Storage Manager
TEST "docker run --rm -i -v $PWD:/workspace -w /workspace crystallang/crystal:1.2.0-alpine /bin/sh -c \"apk add --update --no-cache --force-overwrite sqlite-dev sqlite-static && shards install && shards build --static\""

# Install the Static binary to all containers/nodes
# and copy the service files
nodes.each do |node|
  TEST "docker cp ./bin/gluster-metrics-exporter #{node}:/usr/sbin/gluster-metrics-exporter"
  TEST "docker cp extra/gluster-metrics-exporter.service #{node}:/lib/systemd/system/"
end

# Sanity test
USE_NODE nodes[0]
puts TEST "gluster-metrics-exporter --version"
