package config

import (
	"os"
	"strings"

	"github.com/juju/loggo"
	flag "github.com/spf13/pflag"
	"github.com/spf13/viper"
)

type Credential struct {
	Username string `mapstructure:"username"`
	Password string `mapstructure:"password"`
	AuthType string `mapstructure:"authtype"`
}

type Source struct {
	Host        string      `mapstructure:"host"`
	Port        int         `mapstructure:"port"`
	Credentials string      `mapstructure:"credentials"`
	Partitions  []string    `mapstructure:"partitions"`
}

type ExporterConfig struct {
	BindAddress string `mapstructure:"bind_address"`
	BindPort    int    `mapstructure:"bind_port"`
	LogLevel    string `mapstructure:"log_level"`
	Namespace   string `mapstructure:"namespace"`
}

type Config struct {
	Exporter    ExporterConfig        `mapstructure:"exporter"`
	Credentials map[string]Credential `mapstructure:"credentials"`
	Sources     map[string]Source     `mapstructure:"sources"`
}

var logger = loggo.GetLogger("")

func init() {
	loggo.ConfigureLoggers("<root>=INFO")

	var configFile string
	flag.StringVar(&configFile, "config", "config.yaml", "Path to config file")
	flag.Parse()

	viper.SetConfigType("yaml")

	viper.SetDefault("exporter.namespace", "bigip")
	viper.SetDefault("exporter.bind_address", "0.0.0.0")
	viper.SetDefault("exporter.bind_port", 9142)

	readConfigFile(configFile)

	logLevel := viper.GetString("exporter.log_level")
	logger.Infof("Using log level '%s'", logLevel)

	if _, validLevel := loggo.ParseLevel(logLevel); validLevel {
		loggo.ConfigureLoggers("<root>=" + strings.ToUpper(logLevel))
		return
	}

	logger.Warningf("Invalid log level - Using info")
}

func readConfigFile(fileName string) {
	logger.Debugf("Reading config file %s", fileName)
	file, err := os.Open(fileName)
	if err != nil {
		logger.Criticalf("Failed to open configuration file: %s", err)
		return
	}
	defer file.Close()
	if err := viper.ReadConfig(file); err != nil {
		logger.Criticalf("Failed to parse configuration file: %s", err)
		return
	}
	logger.Infof("Successfully loaded configuration")
}

// GetConfig returns an instance of Config containing the resulting parameters
// to the program
func GetConfig() *Config {
	var cfg Config
	if err := viper.Unmarshal(&cfg); err != nil {
		logger.Criticalf("Failed to unmarshal config: %s", err)
		os.Exit(1)
	}
	return &cfg
}
