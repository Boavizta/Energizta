#!/bin/bash

### Work in progress
### Tests to retrieve a list of hardware that is exaustive but not too verbose
### We need this to generate ids that are unique for a given host + hardware + OS
### We want one of the part to change if a hardrive is change, if RAM is added, or if the OS is update

machine_id () {
    # cat /etc/machine-id # Can change at every reboot?
    lsblk -o UUID,MOUNTPOINT | grep ' /$' -m 1 | cut -d ' ' -f 1
}

hardware () {
    lshw -short | tail -n +4 | grep -v "  volume  " | sed "s/ *disk */ /" | sed -E "s/.*  //" | grep -Ev "Ethernet interface|PnP device"
}

software () {
    arch
    uname -a
    lsb_release -ds
}

MSUM=$(machine_id)
HSUM=$(hardware | md5sum | awk '{print $1}')
SSUM=$(software | md5sum | awk '{print $1}')

id () {
    echo "$MSUM-$HSUM-$SSUM"
}

if [ "$1" == '--id' ] ; then
    id
else
    echo "{\"$HSUM\":" \"
    hardware
    echo "\","
    echo "\"$SSUM\":" \"
    software
    echo "\"}"
fi
