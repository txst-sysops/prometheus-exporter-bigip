#!/bin/bash

DOCKER=$( ( which podman || which docker ) | head -1 )
if [[ -z "$DOCKER" || ! -e "$DOCKER" ]]; then
	echo "Cannot find any podman or docker executable in PATH" >&2
	exit 1
fi

cd "$( dirname "$0" )"

PROJECT_NAME=$( cat build.json | jq -r .project_name )

fmt(){
	find . -not -path "./vendor/*" -name "*.go" -exec go fmt {} \;
}

preflight(){
	if [[ $( git status --porcelain=1 | wc -l ) -gt 0 ]]; then
		echo "You have unstaged modifications in your repo." >&2
		echo "Please commit and tag the new version before running build script." >&2
		exit 1
	fi
}

build(){
	version=$( git tag --list --sort=version:refname | tail -1 )
	echo "Initiating build process for version $version" >&2

	tmp=$(mktemp)
	"$DOCKER" build . -t "$id" | tee /dev/stderr > $tmp
	if [[ $? != 0 ]]; then
		echo "Docker build failed"
		exit 1
	fi
	id=$( cat "$tmp" | awk 'END {print $3}' )
	rm -f "$tmp"

	echo $id
	docker tag $id expressenab/bigip_exporter:$version
	docker tag $id expressenab/bigip_exporter:latest
	#docker push expressenab/bigip_exporter:$version
	#docker push expressenab/bigip_exporter:latest
}

preflight
if [[ $1 == "fmt" ]]; then
	fmt
else
	build 
fi
