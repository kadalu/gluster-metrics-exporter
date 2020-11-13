# gluster-metrics - Prometheus exporter

## Install

Download the latest release with the command

```
curl -L https://github.com/kadalu/gluster-metrics-exporter/releases/download/0.1.1/gluster-metrics-exporter-`uname -m | sed 's|aarch64|arm64|' | sed 's|x86_64|amd64|'` -o gluster-metrics-exporter
```

Make the `gluster-metrics-exporter` binary executable.

```
chmod +x ./gluster-metrics-exporter
```

Move the binary in to your PATH.

```
sudo mv ./gluster-metrics-exporter /usr/local/bin/gluster-metrics-exporter
```

Test to ensure the version you installed is up-to-date

```
$ gluster-metrics-exporter --version
```

## Usage:

```
Usage: gluster-metrics-exporter [OPTIONS]
    --metrics-path=URL               Metrics Path (default: /metrics)
    --cluster-metrics-path=URL       Cluster Metrics Path (default: /clustermetrics)
    -p PORT, --port=PORT             Exporter Port (default: 9713)
    --cluster=NAME                   Cluster identifier
    --gluster-host=NAME              Gluster Host to replace `localhost` from the peer command output (default: hostname)
    -v, --verbose                    Enable verbose output (default: false)
    --disable-all                    Disable all Metrics (default: false)
    --disable-volumes-all            Disable all Volumes (default: false)
    --enable=NAMES                   Enable specific Metric Groups
    --disable=NAMES                  Disable specific Metric Groups (default: [])
    --enable-volumes=NAMES           Enable specific Volumes
    --disable-volumes=NAMES          Disable specific Volumes (default: [])
    --log-level=LEVEL                Log Level (default: info)
    --log-dir=DIR                    Log directory (default: /var/log/gluster-metrics)
    --log-file=NAME                  Log file (default: exporter.log)
    --glusterd-dir=DIR               Glusterd directory (default: /var/lib/glusterd)
    --gluster-cli-path=PATH          Gluster CLI Path (default: /usr/sbin/gluster)
    --gluster-cli-sock=SOCK          Gluster CLI socket file (default: )
    --version                        Show version information
    --config=FILE                    Config file
    -h, --help                       Show this help
```
