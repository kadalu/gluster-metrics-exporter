#!/bin/bash

curl -fsSL https://github.com/kadalu/gluster-metrics-exporter/releases/latest/download/gluster-metrics-exporter-`uname -m | sed 's|aarch64|arm64|' | sed 's|x86_64|amd64|'` -o /tmp/gluster-metrics-exporter
curl -fsSL https://github.com/kadalu/gluster-metrics-exporter/releases/latest/download/gluster-metrics-exporter.service -o /tmp/gluster-metrics-exporter.service

install -m 700 /tmp/gluster-metrics-exporter.service /lib/systemd/system/
install /tmp/gluster-metrics-exporter /usr/sbin/gluster-metrics-exporter
