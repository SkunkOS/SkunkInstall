#!/bin/sh -e

if [ `whoami` != 'root' ]; then
    printf "The Skunk Installer must be run by root.\n"
    exit 1
fi

# perl is not part of FreeBSD standard installation
# So have it installed before we continue
env ASSUME_ALWAYS_YES=YES pkg install perl5

# just make sure that that we are on the right path
cd /root

# download the main script to the current directory
fetch https://raw.githubusercontent.com/SkunkOS/SkunkInstaller/main/bootie -o .

# make it executable
chmod 544 bootie

# go
/root/bootie -i -x
