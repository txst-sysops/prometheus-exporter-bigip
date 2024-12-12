module github.com/txst-sysops/prometheus-exporter-bigip

go 1.11

require (
	github.com/txst-sysops/prometheus-exporter-bigip/collector 
	github.com/txst-sysops/prometheus-exporter-bigip/config
	github.com/juju/loggo
	github.com/pr8kerl/f5er/f5
	github.com/prometheus/client_golang/prometheus
)
