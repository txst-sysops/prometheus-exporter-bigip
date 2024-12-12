#!/bin/bash

hosts=$( < /config.json jq -r 'keys | .[]' )

for host in $hosts; do

	bind_port=$( < config.json jq -r ".$host.listener_port" )
	remote_host=$( < config.json jq -r ".$host.remote_host" )
	username=$( < config.json jq -r ".$host.username" )
	password=$( < config.json jq -r ".$host.password" )
	log_level=$( < config.json jq -r ".$host.log_level" )
	if [[ "$log_level" == "null" ]]; then
		log_level="info"
	fi
	
	/bigip_exporter \
		--bigip.host "$remote_host" \
		--bigip.username "$username" \
		--bigip.password "$password" \
		--exporter.bind_port "$bind_port" \
		--exporter.log_level "$log_level" \
		&

done

