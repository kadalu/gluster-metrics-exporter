# Gluster Metrics Exporter

## Install

Download the latest release with the command

```
$ curl -fsSL https://github.com/kadalu/gluster-metrics-exporter/releases/latest/download/install.sh | sudo bash -x
```

Test to ensure the version you installed is up-to-date

```
$ gluster-metrics-exporter --version
```

## Usage:

Start the Gluster Metrics exporter service in all the Storage nodes

```
# systemctl enable gluster-metrics-exporter
# systemctl start gluster-metrics-exporter
```

Above command picks up the Gluster hostname by running the `hostname` command. If the local Gluster hostname is different than create a hostname file in `/var/lib/glusterd`.

```
# echo "server1.example.com" > /var/lib/glusterd/hostname
```

To fetch the Prometheus compatible Metrics, call the API from any one Storage node.

```
$ curl http://server1.example.com:9713/metrics
```

To get the same metrics in JSON format

```
$ curl http://server1.example.com:9713/metrics.json
```

## Manually run the exporter (Without systemd)

```
# gluster-metrics-exporter
```

Available options

```
Usage: gluster-metrics-exporter [OPTIONS]
    --metrics-path=URL               Metrics Path (default: /metrics)
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
