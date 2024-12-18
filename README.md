# BIG-IP exporter
Prometheus exporter for BIG-IP statistics. Uses iControl REST API.

## Get it
Previous versions can be found under [Tags](https://github.com/txst-sysops/prometheus-exporter-bigip/tags) and docker images are available at [Docker Hub](https://hub.docker.com/r/txstsysops/prometheus-exporter-bigip/tags).

## Usage
The bigip_exporter is available as a docker image.
```
podman run -p 9142:9142 -v $PWD/config.yaml:/config.yaml docker.io/txstsysops/prometheus-exporter-bigip:latest
```

### Configuration

Take a look at the [example configuration file](https://github.com/txst-sysops/prometheus-exporter-bigip/blob/master/config.example.yaml) to get a sense of the data structure.

The table below shows dot-notation format for configuration options. Both the credentials and sources list are hashes; where it says NAME below, you would use a discinct name.

The credentials are referenced by name within each source, which makes it easier to update 
credentials in one location instead of having to update each instance. The name you choose 
for credentials never appears anywhere in prometheus metrics.

Config | Default | Description
-------|---------|-------------
exporter.log_level | "INFO" | Log level to use. See [loggo documentation](https://github.com/juju/loggo?tab=readme-ov-file#type-level) for available log levels.
exporter.bind_address | "0.0.0.0" | Address to bind HTTP listener to. DO NOT CHANGE FOR CONTAINERS
exporter.bind_port | 9142 | Port to bind HTTP listener to. DO NOT CHANGE FOR CONTAINERS
exporter.namespace | "bigip" | Custom prometheus namespace to use on all metrics
credentials.NAME.username |  | Login user for bigip appliance
credentials.NAME.password |  | Login password for bigip appliance
credentials.NAME.authtype | "token" | If set to "basic", basic authentication method is used
sources.NAME.host |  | Address or DNS name of the bigip appliance
sources.NAME.port | 443 | Port to connect to the bigip appliance on
sources.NAME.credentials |  | Name of the credentials to use
sources.NAME.partitions |  | Array of bigip partition names to include in metrics. By default, all partitions are included.

### View available metrics endpoints
You can see which endpoints are available using HTTP GET to `/metrics`. The response will include links to each of the configured endpoints, e.g. `/metrics/ltm1`.

## Implemented metrics
* Virtual Server
* Rule
* Pool
* Node

## Prerequisites
* User with read access to iControl REST API

## Tested versions of iControl REST API
Currently only version 12.0.0 and 12.1.1 are tested. If you experience any problems with other versions, create an issue explaining the problem and I'll look at it as soon as possible or if you'd like to contribute with a pull request that would be greatly appreciated.

## Building
### Building locally
Use native podman/docker tools to build a local container image for testing:
```
cd $REPO_DIR
podman build .
```

### Publishing
If you want to publish your own version to the docker registry, be sure to save your registry username + project name into build.json.

1. Run `git status` and make sure all your changes have been committed. If not, go ahead and commit now.
2. Run `git tag` to show the list of existing tags. Identify the "newest" version number (e.g. 1.3.1 is newer than 1.2.17)
3. Create a new tag by incrementing major/minor/revision as needed (`git tag $VERSION`)
4. Run `build.sh` without any arguments
