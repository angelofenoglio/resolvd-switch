#!/bin/bash

# Check if running as root
if [[ $EUID -ne 0 ]]; then
	echo "Must be running as root"
	exit
fi

delete_resolvconf() {
	rm /etc/resolv.conf
	echo "Removed /etc/resolv.conf"
}

restart_networkmanager() {
	systemctl restart NetworkManager
	echo "Restarted NerworkManager"
}

NET_MGR_CONF=/etc/NetworkManager/NetworkManager.conf
DNS_SETTING="dns=default"

stop_resolvd() {
	systemctl disable --quiet systemd-resolved
	systemctl stop systemd-resolved
	echo "Stopped resolved"

	delete_resolvconf

	# Set DNS as default
	sed -i "/$DNS_SETTING/s/^#*//" $NET_MGR_CONF
	echo "Set DNS as default"

	restart_networkmanager
}

start_resolvd() {
	delete_resolvconf

	# Unset DNS
	sed -i "/$DNS_SETTING/s/^#*/#/" $NET_MGR_CONF
	echo "Unset DNS"

	systemctl enable --quiet systemd-resolved
	systemctl start systemd-resolved
	echo "Started resolved"

	restart_networkmanager
}

STATUS="$(systemctl is-active systemd-resolved)"

set -e
case "$1" in
	--stop)
		[[ "$STATUS" == "active" ]] && stop_resolvd || echo "Resolvd not running"
		;;
	--start)
		[[ "$STATUS" == "inactive" ]] && start_resolvd || echo "Resolvd already running"
		;;
	*)
		echo "Usage: (--stop|--start)"
esac

