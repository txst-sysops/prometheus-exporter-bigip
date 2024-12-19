package main

import (
	"net/http"
	"fmt"

	"github.com/txst-sysops/prometheus-exporter-bigip/collector"
	"github.com/txst-sysops/prometheus-exporter-bigip/config"
	"github.com/juju/loggo"
	"github.com/txst-sysops/f5er/f5"
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

func listen(exporterBindAddress string, exporterBindPort int, cfg *config.Config) {
	http.HandleFunc("/metrics", func(w http.ResponseWriter, r *http.Request) {
		target := r.URL.Query().Get("target")
		if target == "" {
			http.Error(w, "Missing 'target' query parameter", http.StatusBadRequest)
			return
		}

		source, exists := cfg.Sources[target]
		if !exists {
			http.Error(w, fmt.Sprintf("Target '%s' not found", target), http.StatusNotFound)
			return
		}

		cred, credExists := cfg.Credentials[source.Credentials]
		if !credExists {
			http.Error(w, fmt.Sprintf("Missing credentials for target '%s'", target), http.StatusInternalServerError)
			return
		}

		sourcePort := configIntDefault(source.Port, 443)
		bigipEndpoint := fmt.Sprintf("%s:%d", source.Host, sourcePort)
		authMethod := f5.TOKEN
		if cred.AuthType == "basic" {
			authMethod = f5.BASIC_AUTH
		}

		// Create a new BIG-IP client for this request
		bigip := f5.New(bigipEndpoint, cred.Username, cred.Password, authMethod)

		// Create a new collector for this request
		bigipCollector, err := collector.NewBigipCollector(bigip, cfg.Exporter.Namespace, source.Partitions)
		if err != nil {
			http.Error(w, fmt.Sprintf("Failed to create collector: %s", err), http.StatusInternalServerError)
			return
		}

		// Use a temporary registry for this request
		registry := prometheus.NewRegistry()
		registry.MustRegister(bigipCollector)

		// Serve metrics using the temporary registry
		promhttp.HandlerFor(registry, promhttp.HandlerOpts{}).ServeHTTP(w, r)
	})

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte(`<html>
			<head><title>BIG-IP Exporter</title></head>
			<body>
			<h1>BIG-IP Exporter</h1>
			<p>Available targets:</p>
			<ul>
		`))
		for sourceName := range cfg.Sources {
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
	// Load the configuration
	cfg := config.GetConfig()

	// Validate configuration
	if len(cfg.Sources) == 0 {
		logger.Criticalf("No sources configured. Exiting.")
		return
	}
	if len(cfg.Credentials) == 0 {
		logger.Criticalf("No credentials configured. Exiting.")
		return
	}

	// Start the HTTP server
	listen(cfg.Exporter.BindAddress, cfg.Exporter.BindPort, cfg)
}

