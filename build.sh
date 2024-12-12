#!/bin/bash

DOCKER=$( ( which podman || which docker ) | head -1 )
if [[ -z "$DOCKER" || ! -e "$DOCKER" ]]; then
	echo "Cannot find any podman or docker executable in PATH" >&2
	exit 1
fi

cd "$( dirname "$0" )"

REGISTRY_NAME=$( cat build.json | jq -r .registry_name )
OWNER_NAME=$(    cat build.json | jq -r .owner_name    )
PROJECT_NAME=$(  cat build.json | jq -r .project_name  )

fmt(){
	find . -not -path "./vendor/*" -name "*.go" -exec go fmt {} \;
}

preflight(){
	if [[ $( git status --porcelain=1 | wc -l ) -gt 0 ]]; then
		echo "You have unstaged modifications in your repo." >&2
		echo "Please commit and tag the new version before running build script." >&2
		exit 1
	fi

	if [[ "$( $DOCKER login --get-login "$REGISTRY_NAME" )" != "$OWNER_NAME" ]]; then
		echo "You need to log in to the registry first." >&2
		echo "Run: $DOCKER login $REGISTRY_NAME -u $OWNER_NAME" >&2
		exit 1
	fi
}

build(){
	version=$( git tag --list --sort=version:refname | tail -1 )
	echo "Initiating build process for version $version" >&2

	tmp=$(mktemp)
	tail -f $tmp 2>/dev/null &
	tailpid=$!
	"$DOCKER" build . --tag "$version" > $tmp
	if [[ $? != 0 ]]; then
		echo "Docker build failed"
		exit 1
	fi
	kill -9 $tailpid >/dev/null 2>/dev/null
	id=$( cat "$tmp" | awk 'END {print $3}' )
	echo rm -f "$tmp"

	echo $id
	$DOCKER tag $id $OWNER_NAME/$PROJECT_NAME:$version
	$DOCKER tag $id $OWNER_NAME/$PROJECT_NAME:latest
	$DOCKER push $OWNER_NAME/$PROJECT_NAME:$version
	$DOCKER push $OWNER_NAME/$PROJECT_NAME:latest
}

preflight
if [[ $1 == "fmt" ]]; then
	fmt
else
	build 
fi
