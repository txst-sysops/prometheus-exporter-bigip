package main

import (
	"net/http"
	"fmt"

	"github.com/txst-sysops/prometheus-exporter-bigip/collector"
	"github.com/txst-sysops/prometheus-exporter-bigip/config"
	"github.com/juju/loggo"
	"github.com/pr8kerl/f5er/f5"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

var logger = loggo.GetLogger("")

func configStringDefault(value string, fallback string) string {
	if value != "" {
		return value
	}
	return fallback
}

func configIntDefault(value int, fallback int) int {
	if value != 0 {
		return value
	}
	return fallback
}

func listen(exporterBindAddress string, exporterBindPort int, sources map[string]*prometheus.Registry) {
    // Handler for the /metrics endpoint
    http.HandleFunc("/metrics", func(w http.ResponseWriter, r *http.Request) {
        target := r.URL.Query().Get("target")
        if target == "" {
            http.Error(w, "Missing 'target' query parameter", http.StatusBadRequest)
            return
        }

        registry, ok := sources[target]
        if !ok {
            http.Error(w, fmt.Sprintf("Target '%s' not found", target), http.StatusNotFound)
            return
        }

        // Serve metrics using the matching registry
        promhttp.HandlerFor(registry, promhttp.HandlerOpts{}).ServeHTTP(w, r)
    })

    // Root endpoint for listing available targets
    http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
        w.Write([]byte(`<html>
            <head><title>BIG-IP Exporter</title></head>
            <body>
            <h1>BIG-IP Exporter</h1>
            <p>Available targets:</p>
            <ul>
        `))
        for sourceName := range sources {
            w.Write([]byte(fmt.Sprintf(`<li><a href="/metrics?target=%s">%s</a></li>
			`, sourceName, sourceName)))
        }
        w.Write([]byte(`</ul>
            </body>
            </html>
        `))
    })

    exporterBind := fmt.Sprintf("%s:%d", exporterBindAddress, exporterBindPort)
    logger.Infof("Exporter listening on %s", exporterBind)
    logger.Criticalf("Process failed: %s", http.ListenAndServe(exporterBind, nil))
}

func main() {
	cfg := config.GetConfig()

	// Map to hold separate registries for each source
	sourceRegistries := make(map[string]*prometheus.Registry)

	for name, source := range cfg.Sources {
		cred, exists := cfg.Credentials[source.Credentials]
		if !exists {
			logger.Criticalf("Missing %s credentials for source %s", source.Credentials, name)
			continue
		}

		sourcePort := configIntDefault(source.Port, 443)
		bigipEndpoint := fmt.Sprintf("%s:%d", source.Host, sourcePort)
		authMethod := f5.TOKEN
		if cred.AuthType == "basic" {
			authMethod = f5.BASIC_AUTH
		}

		bigip := f5.New(bigipEndpoint, cred.Username, cred.Password, authMethod)

		bigipCollector, err := collector.NewBigipCollector(bigip, cfg.Exporter.Namespace, source.Partitions)
		if err != nil {
			logger.Criticalf("Failed to create collector for %s: %s", name, err)
			continue
		}

		registry := prometheus.NewRegistry()
		registry.MustRegister(bigipCollector)
		sourceRegistries[name] = registry
	}

	listen(cfg.Exporter.BindAddress, cfg.Exporter.BindPort, sourceRegistries)
}

