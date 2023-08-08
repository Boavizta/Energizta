#!/bin/bash

### Usage: energizta.sh [--stresstest] [--stressfile file.txt] [--interval 5] [--warmup 20] [--duration 60]...
###
### Main options:
###   --interval INTERVAL   Measure server state each INTERVAL seconds (default 5)
###   --duration DURATION   Stop each stresstest after DURATION seconds (default 60)
###   --manual-input        Ask the user to enter power metrics manually (from a Wattmeter…)
###   --once                Do not loop, print one state and exit
###
### Stresstest options:
###   --stresstest          Run a stresstest
###   --stressfile FILEPATH Load alternative stress tests commands from a file instead of default stresstest
###   --warmup WARMUP       Wait WARMUP seconds after lauching a stresstest before measuring state (default 20)
###   --send-to-db          Send the stresstest results to Boavizta's Energizta collaborative database
###
### Display options:
###   --debug               Display debug outputs
###   --continuous          Display the current state every INTERVAL seconds instead of an average state every DURATION seconds
###   --energy-only         Only displays energy variables instead of global state (load, cpu, etc.)
###   --with_timestamp      Include timestamp in displayed variables
###   --with_date           Include datetime in displayed variables
###   --short-host-id       Use shorter string as HOST_ID and avoid the need for lshw (not compatible with --send-to-db)
###   --force-host-id ID    Force an alternative HOST_ID, use $(hostname) for instance (not compatible with --send-to-db)
###
### Wattmeter sources:
###   --ipmi-sensor-id ID   Name of sensor to get power from in `ipmitool sensor`
###   --shellyplug-url URL  Shelly Plug URL (ex: http://192.168.33.1 or http://admin:password@192.168.33)
###
### Misc options :
###   --force-without-root  Force the script to run with current user
###   --help                Display this help
###
### Examples :
###   sudo ./energizta.sh # Measure every 5 seconds and display a state every 60 seconds
###   sudo ./energizta.sh --interval 1 --duration 1 --once # Just do one measure and print the result
###   sudo ./energizta.sh --continuous # Measure and display a state every 5 seconds
###   sudo ./energizta.sh --stresstest --send-to-db # Do a stress test and send states to Boavizta
###
### This script need to be run as root because RAPL and DCMI power metrics are only accessible by root.
###

# IDEAS :
# - Allow to have an "additionnal facts" option to run a script that will get more facts


VERSION="0.3"
ENERGIZTA_DB_URL="https://energizta-db.boavizta.org"

if ! ((BASH_VERSINFO[0] >= 4)); then
    >&2 echo "This script needs to be run with bash >= 4."
    exit 1
fi

if hostnamectl status | grep -q 'Chassis: vm'; then
    >&2 echo "This script does not work on virtual servers."
    exit 1
fi

if hostnamectl status | grep -q 'Chassis: container'; then
    >&2 echo "This script does not work in containers."
    exit 1
fi

usage () {
    sed -rn 's/^### ?//;T;p' "$0"
    echo "v$VERSION"
}

info () {
    echo "-- $(date +"%Y-%m-%d %H:%M:%S") - INFO: $1"
}

debug () {
    if $DEBUG; then
        echo "-- $(date +"%Y-%m-%d %H:%M:%S") - DEBUG: $1"
    fi
}

INTERVAL=5
WARMUP=20
DURATION=60
ONCE=false
CONTINUOUS=false
ENERGY_ONLY=false
STRESSTEST=false
MANUAL_INPUT=false
DEBUG=false
FORCE_WITHOUT_ROOT=false
WITH_TIMESTAMP=false
WITH_DATE=false
REGISTER_ON_DB=false
SEND_TO_DB=false
HOST_ID=""
#MACHINE_ID=$(cat /etc/machine-id) # Can change at every reboot?
MACHINE_ID=$(lsblk -o UUID,MOUNTPOINT 2>/dev/null | grep ' /$' -m 1 | cut -d ' ' -f 1)

while [ -n "$1" ]; do
    case $1 in
        --interval) shift; INTERVAL=$1 ;;
        --duration) shift; DURATION=$1 ;;
        --once) ONCE=true ;;
        --manual-input) MANUAL_INPUT=true ;;
        --ipmi-sensor-id) shift; IPMI_SENSOR_ID=$1 ;;
        --shellyplug-url) shift; SHELLYPLUG_URL=$1 ;;

        --stresstest) STRESSTEST=true ;;
        --stressfile) shift; STRESSTEST=true; STRESSFILE=$1 ;;
        --warmup) shift; WARMUP=$1 ;;

        --send-to-db) SEND_TO_DB=true; REGISTER_ON_DB=true ;;
        --short-host-id) HOST_ID=$MACHINE_ID ;;
        --force-host-id) shift; HOST_ID=$1 ;;

        --continuous) CONTINUOUS=true ;;
        --energy-only) ENERGY_ONLY=true ;;
        --with-timestamp) WITH_TIMESTAMP=true ;;
        --with-date) WITH_DATE=true ;;
        --debug) DEBUG=true ;;

        --force-without-root) FORCE_WITHOUT_ROOT=true ;;
        --help) usage; exit 0;;
        -h) usage; exit 0;;
        *) usage; exit 1;;
    esac
    shift
done


if [ -n "$USER" ] && [ "$USER" != "root" ] && ! $FORCE_WITHOUT_ROOT; then
    >&2 echo "This script must be run as root."
    exit 1
fi


if [ -z "$HOST_ID" ] ; then
    if $FORCE_WITHOUT_ROOT; then
        >&2 echo "With --force-without-root you need to use --short-host-id or --force-host-id"
        exit 1
    fi

    if ! command -v lshw > /dev/null; then
        >&2 echo "Please install lshw command."
        exit 1
    fi

    # Remove header | Filter out some unused lines | Convert line by line to json dicts (with 2 or 3 keys) | Convert everthing to json list
    # Parsing `lshw -json` with jq could be easier but we do not want jq as a dependency
    # So let's hope `lshw -short` format does not change too much
    hardware="$(lshw -short 2>/dev/null | sed '0,/^=======/d' | grep -Ev "Ethernet interface|PnP device|Project-Id-Version" | grep -Ev "  (volume|bus)  " | sed 's/^[^ ]*  *//g' | sed -r 's/^([^ ]+)  +([^ ]+)  +(.*)/{"system": "\2", "logicalname": "\1",  "product": "\3"}/g' | sed -r 's/^([^ ]+)  +(.*)$/{"class": "\1", "product": "\2"}/g' | sed ':a; N; $!ba; s/\n/,\n/g' | sed '1 i\[' | sed '$a\]')"

    software="{\"arch\": \"$(arch)\", \"uname\": \"$(uname -a | awk '{ $2="";print}')\", \"distrib\": \"$(lsb_release -ds)\"}"

    hardware_id=$(echo "$hardware" | md5sum | awk '{print $1}')
    software_id=$(echo "$software" | md5sum | awk '{print $1}')

    HOST_ID="${MACHINE_ID}_${hardware_id}_${software_id}"

    HOST="""
{
\"id\": \"$HOST_ID\",
\"hardware\": $hardware,
\"software\": $software
}
"""
fi

if $REGISTER_ON_DB; then
    if [ -z "$HOST" ]; then
        >&2 echo "You cannot use both --short-host-id or --force-host-id AND --send-to-db"
        exit 1
    fi
    if ! command -v curl > /dev/null; then
        >&2 echo "Please install curl command."
        exit 1
    fi
    TMPFILE=$(mktemp /tmp/energizta-XXXXXX.json)
fi

if ! command -v ipmi-dcmi > /dev/null; then
    >&2 echo "You should try to install ipmi-dcmi (package freeipmi-tools)"
fi
# This command can hangs indefinitely so we have to test it with timeout
dcmi=$(timeout 1 /usr/sbin/ipmi-dcmi --get-system-power-statistics 2>/dev/null || true )
DCMI=false
if echo "$dcmi" | grep -q 'Active$'; then
    if [ "$(echo "$dcmi" | grep 'Current Power' | awk '{print $4}')" -gt 0 ]; then
        DCMI=true
    else
        debug "ipmi-dcmi Current Power = 0, ignoring"
    fi
else
    debug "ipmi-dcmi does not work"
fi

if ! $DCMI && [ -z "$IPMI_SENSOR_ID" ]; then
    debug "ipmi-dcmi does not work, trying ipmitool sensor"
    if ! command -v ipmitool > /dev/null; then
        >&2 echo "You should try to install ipmitool"
    fi
    IPMI_SENSOR_ID=$(timeout 10 ipmitool sensor 2>/dev/null | grep Watt | tail -n 1 | sed 's/  .*//g' || true)
    if [ -n "$IPMI_SENSOR_ID" ]; then
        debug "Found IPMI sensor id $IPMI_SENSOR_ID"
    fi
fi

IPMI_SENSOR_NAME=$(echo "$IPMI_SENSOR_ID" | tr '[:upper:]' '[:lower:]' | sed 's/ /_/g')

if [ -n "$SHELLYPLUG_URL" ]; then
    if [ -z "$(curl -s -X GET "$SHELLYPLUG_URL/status" | jq -r '.meters[0].power')" ]; then
        >&2 echo "Could not find power in ShellyPlug. Please check ShellyPlug URL."
        exit 1
    fi
fi

if $STRESSTEST && $ONCE; then
    >&2 echo "You cannot use --once and --stresstest together."
    usage
    exit 1
fi

if $SEND_TO_DB && ! $STRESSTEST; then
    >&2 echo "--send-to-db needs to be used with --stress-test."
    usage
    exit 1
fi

if [ -n "$STRESSFILE" ]; then
    if [ -f "$STRESSFILE" ]; then
        stresstests=$(cat "$STRESSFILE")
    else
        >&2 echo "$STRESSFILE does not exist"
        exit 1
    fi
else
    _stresstests () {
        cores=$(grep -c '^processor' /proc/cpuinfo)

        echo "sleep $((DURATION + 30))"

        i=1;
        while [ $i -le "$cores" ]; do
            echo "stress-ng -q --cpu $i"
            echo "stress-ng -q --getrandom $i"
            echo "stress-ng -q --iomix $i"
            echo "stress-ng -q --memrate $i"
            i=$((i * 2))
        done

        echo "stress-ng -q --io 2"
        echo "stress-ng -q --hdd 2"
        echo "stress-ng -q --io 2 --hdd 2"
    }
    stresstests="$(_stresstests)"
fi


declare -gA state
declare -gA avg_state
declare -gA last_state


compute_avg_state() {
    if [ -z "${avg_state[nb_states]}" ]; then
        avg_state[nb_states]=1
    else
        avg_state[nb_states]=$((avg_state[nb_states] + 1))
    fi
    for j in "${!state[@]}"; do
        if [[ ! "$j" =~ ^(_.*|energizta_version|timestamp|date)$ ]]; then
            if [ -z "${avg_state[$j]}" ]; then
                avg_state[$j]=${state[$j]}
            else
                # :TODO:maethor:20221027: I think float manipulation could be better
                avg_state[$j]=$(echo "${avg_state[$j]} + ((${state[$j]} - ${avg_state[$j]}) / ${avg_state[nb_states]})" | bc)
            fi
        fi
    done
    avg_state[duration_us]=$((avg_state[duration_us]+state[interval_us]))
    $WITH_TIMESTAMP && avg_state[timestamp]=$(date +%s)
    $WITH_DATE && avg_state[date]=$(date +'%Y-%m-%d %H:%M:%S')
    avg_state[energizta_version]=$ENERGIZTA_VERSION
}

compute_state() {
    unset state
    declare -gA state

    state[_date]=$(date +%s%6N)
    # shellcheck disable=SC2004
    if [ -n "${last_state[_date]}" ]; then
        interval_us=$((${state[_date]} - ${last_state[_date]}))
    else
        interval_us=0
    fi
    interval_s=$((interval_us / 1000000))
    state[interval_us]=$interval_us
    state[_interval_s]=$interval_s
    $WITH_TIMESTAMP && state[timestamp]=$(date +%s)
    $WITH_DATE && state[date]=$(date +'%Y-%m-%d %H:%M:%S')
    #state[date]=$(date +%s)

    if ! $ENERGY_ONLY; then
        state[energizta_version]="$VERSION"

        state[load1]=$(cut -d ' ' -f 1 < /proc/loadavg)
        state[cpu_freq_mhz]=$(grep "^cpu MHz" /proc/cpuinfo | awk '{x+=$4} END {printf "%.0f\n", x/NR}')

        # Procstat
        if [ -f "/proc/stat" ]; then
            PROCSTAT="$(grep 'cpu ' /proc/stat)"
            state[_cpu_usr]=$(echo "$PROCSTAT" | awk '{print $2}')
            state[_cpu_sys]=$(echo "$PROCSTAT" | awk '{print $4}')
            state[_cpu_idle]=$(echo "$PROCSTAT" | awk '{print $5}')
            state[_cpu_iowait]=$(echo "$PROCSTAT" | awk '{print $6}')
            if [ "$interval_s" -gt 0 ]; then
                cpu_idle=$((state[_cpu_idle] - last_state[_cpu_idle]))
                cpu_usr=$((state[_cpu_usr] - last_state[_cpu_usr]))
                cpu_sys=$((state[_cpu_sys] - last_state[_cpu_sys]))
                cpu_iowait=$((state[_cpu_iowait] - last_state[_cpu_iowait]))
                cpu_total=$((cpu_idle+cpu_usr+cpu_sys+cpu_iowait))
                state[cpu_usr_pct]=$(((cpu_usr*100)/cpu_total))
                state[cpu_sys_pct]=$(((cpu_sys*100)/cpu_total))
                state[cpu_iowait_pct]=$(((cpu_iowait*100)/cpu_total))
            fi
        fi

        # Meminfo
        meminfo=$(grep -E '^(MemTotal|MemFree|Buffers|Cached)' /proc/meminfo)
        mem_total=$(echo "$meminfo" | grep MemTotal | awk '{print $2}')
        mem_free=$(echo "$meminfo" | grep MemFree | awk '{print $2}')
        mem_buffers=$(echo "$meminfo" | grep Buffers | awk '{print $2}')
        mem_cached=$(echo "$meminfo" | grep Cached | awk '{print $2}')
        state[mem_total_MB]=$((mem_total / 1024))
        state[mem_free_MB]=$((mem_free / 1024))
        state[mem_used_MB]=$(((mem_total - mem_free - mem_buffers - mem_cached) / 1024))

        # Diskstats
        # kernel handles sectors by 512bytes
        # http://www.mjmwired.net/kernel/Documentation/block/stat.txt
        SECTOR_SIZE_BYTE=512

        if [ -f "/proc/diskstats" ]; then
            DISKSTATS="$(cat /proc/diskstats)"
            for dev in /sys/block/*; do
                dev="${dev##*/}"
                if [ -L "/sys/block/$dev/device" ]; then
                    state[_${dev}_sectors_read]=$(echo "$DISKSTATS" | grep " $dev " | awk '{print $6}')
                    state[_${dev}_sectors_write]=$(echo "$DISKSTATS" | grep " $dev " | awk '{print $10}')
                    state[_${dev}_time_io_ms]=$(echo "$DISKSTATS" | grep " $dev " | awk '{print $13}')
                    if [ "$interval_s" -gt 0 ]; then
                        state[${dev}_read_kBps]=$(((${state[_${dev}_sectors_read]} - ${last_state[_${dev}_sectors_read]}) * SECTOR_SIZE_BYTE / interval_s / 1024))
                        state[${dev}_write_kBps]=$(((${state[_${dev}_sectors_write]} - ${last_state[_${dev}_sectors_write]}) * SECTOR_SIZE_BYTE / interval_s / 1024))
                        state[_${dev}_delta_time_io_ms]=$((${state[_${dev}_time_io_ms]} - ${last_state[_${dev}_time_io_ms]}))
                        state[${dev}_pct_busy]=$((100 * ${state[_${dev}_delta_time_io_ms]} / (interval_us / 1000)))
                    fi
                fi
            done
        fi

        # Netstats
        NETSTAT=$(cat /proc/net/dev)
        for netint in /sys/class/net/*/device; do
            netint=$(echo "$netint" | cut -d '/' -f 5)
            state[_${netint}_bytes_recv]=$(echo "$NETSTAT" | grep "$netint:" | awk '{print $2}')
            state[_${netint}_packets_recv]=$(echo "$NETSTAT" | grep "$netint:" | awk '{print $3}')
            state[_${netint}_bytes_sent]=$(echo "$NETSTAT" | grep "$netint:" | awk '{print $10}')
            state[_${netint}_packets_sent]=$(echo "$NETSTAT" | grep "$netint:" | awk '{print $11}')
            if [ "$interval_s" -gt 0 ]; then
                state[${netint}_recv_kBps]=$(((${state[_${netint}_bytes_recv]} - ${last_state[_${netint}_bytes_recv]}) / interval_s / 1024))
                state[${netint}_sent_kBps]=$(((${state[_${netint}_bytes_sent]} - ${last_state[_${netint}_bytes_sent]}) / interval_s / 1024))
                state[${netint}_recv_packetsps]=$(((${state[_${netint}_packets_recv]} - ${last_state[_${netint}_packets_recv]}) / interval_s))
                state[${netint}_sent_packetsps]=$(((${state[_${netint}_packets_sent]} - ${last_state[_${netint}_packets_sent]}) / interval_s))
            fi
        done
    fi

    # Sensors
    if [ -n "$(which sensors)" ]; then
        sensors_acpi_watt=$(sensors power_meter-acpi-0 2>/dev/null | grep power1 | grep -v '4.29 MW' | awk '{print $2}')
        if [ -n "$sensors_acpi_watt" ]; then
            state[sensors_acpi_watt]=$sensors_acpi_watt
        fi
        if ! $ENERGY_ONLY; then
            sensors_coretemp=$(sensors coretemp-isa-0000 2>/dev/null | grep 'Package id 0' | grep -Eo '[0-9\.]*' | head -n 2 | tail -n 1)
            if [ -n "$sensors_coretemp" ]; then
                state[sensors_coretemp]=$sensors_coretemp
            fi
        fi
    fi

    # RAPL
    if [ -e /sys/class/powercap/intel-rapl:0 ] && [ -r /sys/class/powercap/intel-rapl:0/energy_uj ]; then
        for package in /sys/class/powercap/intel-rapl:*; do
            i=$(echo "$package" | cut -d ':' -f 2)
            name=$(cat "$package/name")
            if [ "$name" == "dram" ]; then
                name=dram_$i
            elif [[ "$name" == package* ]]; then
                name=package_$i
            elif [[ "$name" == psys ]]; then
                name=psys_$i
            else
                # For now we only manage package-X and dram
                continue
            fi

            state[_rapl_${name}_energy_uj]=$(cat "$package/energy_uj")

            if [ "$interval_s" -gt 0 ]; then
                delta_uj=$((${state[_rapl_${name}_energy_uj]} - ${last_state[_rapl_${name}_energy_uj]}))

                if [ "$delta_uj" -lt 0 ]; then
                    max_energy_range_uj=$(cat "$package/max_energy_range_uj")
                    delta_uj=$((delta_uj + max_energy_range_uj))
                fi

                (( state[_rapl_total_delta_energy_uj]+=delta_uj ))
                state[rapl_${name}_watt]=$((delta_uj / (interval_us)))
                if ! [[ "$name" == psys_* ]]; then
                    state[rapl_total_watt]=$((state[rapl_total_watt] + (delta_uj / (interval_us))))
                    state[_rapl_nb_src]=$((state[_rapl_nb_src] + 1))
                else
                    state[rapl_totalpsys_watt]=$((state[rapl_totalpsys_watt] + (delta_uj / (interval_us))))
                fi
            fi

        done
    fi

    # DCMI
    if $DCMI; then
        dcmi=$(timeout .3 /usr/sbin/ipmi-dcmi --get-system-power-statistics 2>/dev/null || true)
        if echo "$dcmi" | grep -q 'Active$'; then
            state[dcmi_cur_watt]=$(echo "$dcmi" | grep 'Current Power' | awk '{print $4}')
        fi
    fi

    # IPMITOOL
    if [ -n "$IPMI_SENSOR_ID" ]; then
        ipmi_watt=$(timeout 3 ipmitool sdr get "$IPMI_SENSOR_ID" | grep 'Sensor Reading' | grep -Eo '[0-9]+' | head -n 1 || true)
        if [ -n "$ipmi_watt" ]; then
            state[ipmi_${IPMI_SENSOR_NAME}_watt]=$ipmi_watt
        fi
    fi


    state_string=$(declare -p state)
    eval "declare -gA last_state=${state_string#*=}"

    # Shellyplug
    if [ -n "$SHELLYPLUG_URL" ]; then
        shellyplug_watt="$(curl -s -X GET "$SHELLYPLUG_URL/status" | jq -r '.meters[0].power')"
        if [ -n "$shellyplug_watt" ]; then
            # shellcheck disable=SC2154
            state['shellyplug_watt']=$(echo "$shellyplug_watt" | xargs printf "%.*f\n" "$p") # Round to integer
        fi
    fi
}

get_manual_input() {
    if $MANUAL_INPUT; then
        read -rp "Enter the average power in Watt for the last $((state[interval_us] / 1000000)) seconds (int or float, in Watt): " input </dev/tty 2>/dev/tty
        while ! [[ $input =~ ^[+-]?[0-9]+\.?[0-9]*$ ]]; do
            read -rp "\"$input\" is not an int or a float: " input </dev/tty 2>/dev/tty
        done
        state[manual_input_watt]=$input
    fi
}

print_state() {
    # Can help for debug
    #for j in "${!state[@]}"; do
        #if [[ ! "$j" == _* ]]; then
            #echo "$j"
            #echo "${state[$j]}"
        #fi
    #done | jq -n -R -c 'reduce inputs as $j ({}; . + { ($j): (input|(tonumber? // .)) })'
    comment="$1"
    (
    echo "{"
    $ENERGY_ONLY || echo "\"host\": \"$HOST_ID\","
    echo "\"interval_us\": ${state[interval_us]},"
    [ -n "${state[timestamp]}" ] && echo "\"timestamp\": ${state[timestamp]},"
    [ -n "${state[date]}" ] && echo "\"date\": \"${state[date]}\","
    [ -n "${state[duration_us]}" ] && echo "\"duration_us\": ${state[duration_us]},"
    [ -n "${state[nb_states]}" ] && echo "\"nb_states\": ${state[nb_states]},"
    for j in "${!state[@]}"; do
        if [[ ! "$j" == _* ]] && [[ $j =~ ([a-z0-9]_(pct_busy|read_kBps|write_kBps|recv_kBps|sent_kBps|recv_packetsps|sent_packetsps)|cpu_[a-z_]|mem_[a-z_]|load1|sensors_coretemp) ]]; then
            echo "\"$j\": ${state[$j]}",
        fi
    done | sort
    echo "\"powers\": {"
    for j in "${!state[@]}"; do
        if [[ ! "$j" == _* ]] && [[ $j =~ ([a-z0-9_]_watt) ]]; then
            echo "\"$j\": ${state[$j]}",
        fi
    done | sort | sed '$ s/,$//'
    echo "},"
    if [ -n "$comment" ]; then
        echo "\"comment\": \"$comment\","
    fi
    echo "\"energizta_version\": \"$VERSION\"}"
    ) | tr -d '\n'
    echo ""
}

get_states () {
    unset last_state
    declare -gA last_state
    compute_state

    n=0
    while [ $(((INTERVAL * n) + WARMUP)) -lt "$DURATION" ]; do
        sleep "$INTERVAL"
        compute_state
        if $CONTINUOUS; then
            get_manual_input
            print_state
        else
            compute_avg_state
            debug "Intermediate state: $(print_state)"
        fi
        n=$((n+1))
    done

    if ! $CONTINUOUS; then
        debug "Got $n states during $((DURATION - WARMUP))s, merging:"
        avg_state_string=$(declare -p avg_state)
        eval "declare -gA state=${avg_state_string#*=}"
        get_manual_input
        state_json=$(print_state "$1")
        echo "$state_json"
        if $SEND_TO_DB; then
            echo "$state_json" >> "$TMPFILE"
        fi
        unset avg_state
        declare -gA avg_state
    fi
}

if $STRESSTEST; then
    # shellcheck disable=SC2172
    if ! command -v stress-ng > /dev/null; then
        >&2 echo "Please install stress-ng command."
        exit 1
    fi

    nb_tests=$(echo "$stresstests" | grep -vc '^$')
    info "Running $nb_tests tests of ${DURATION}s each, should take $((DURATION * $(echo "$stresstests" | grep -vc '^$')))s"
    t=1

    set -e

    while IFS= read -r stresstest ; do
        echo ""
        if [ -n "$stresstest" ]; then
            info "($t/$nb_tests) Running \"$stresstest\" for $((DURATION)) seconds"
            t=$((t+1))
            $stresstest > /dev/null &
            pid=$!

            trap 'kill "$pid"' SIGHUP SIGINT SIGTERM

            if ! ps -p $pid > /dev/null; then
                info "$stresstest has failed immediately. Stresstest aborted."
                continue
            fi

            debug "-- Warming up for $WARMUP seconds…"
            sleep "$WARMUP"

            if ! ps -p $pid > /dev/null; then
                info "$stresstest has failed during warmup. Stresstest aborted."
                continue
            fi

            debug "-- Starting to get states…"
            get_states "Stresstest: $stresstest"

            kill $pid > /dev/null 2>&1
        fi
    done < <(echo "$stresstests")
else
    if $ONCE; then
        WARMUP=0
        get_states
    else
        while true; do
            WARMUP=0
            get_states
        done
    fi
fi

set +e

# Endgame:
# - register the host on Boavizta's Energizta database
# - and send the results of the run
if $SEND_TO_DB; then
    echo ""
    while true; do
        read -rp "=> Do you still want to send above data to Boavizta's Energizta database? (y/n) " yn
        echo ""
        case $yn in
            [Yy]* ) break;;
            [Nn]* )
                echo "If you change your mind you can still try to send it with this command:"
                echo "curl --upload-file $TMPFILE $ENERGIZTA_DB_URL/pub/states"
                exit
                ;;
            * ) echo "Please answer yes or no.";;
        esac
    done

    echo "Checking if $HOST_ID is registered in Boavizta's Energizta database…"
    case "$(curl "$ENERGIZTA_DB_URL/pub/test_host/$HOST_ID" 2> /dev/null)" in
        "OK" )
            echo "This host is already in DB."
            ;;
        "NOK" )
            echo "We need to register some information about your hardware and software."
            echo "It should be completely anonymous:"
            echo "$HOST"

            while true; do
                read -rp "=> Do you allow to register this on Boavizta's Energizta database? (y/n) " yn
                echo ""
                case $yn in
                    [Yy]* ) break;;
                    [Nn]* ) echo "OK Bye."; exit;; # :TODO:maethor:20230227: If you change your mind…
                    * ) echo "Please answer yes or no.";;
                esac
            done

            echo "Registering $HOST_ID in Boavizta's Energizta database…"
            ret_code="$(curl -s -o /dev/stderr --write-out '%{response_code}' -X POST --header 'content-type: application/json' --data "$HOST" "$ENERGIZTA_DB_URL/pub/host")"
            if [ "$ret_code" -ge 400 ]; then
                echo "Abording. Sorry."
                exit 1
            fi
            echo "This host is now registered."
            ;;
        * )
            echo "Unmanaged exception"
            exit 1
            ;;
    esac

    echo ""

    echo "Sending results to Energizta collaborative database…"
    ret_code=$(curl -s -o /dev/stderr --write-out '%{response_code}' --upload-file "$TMPFILE" "$ENERGIZTA_DB_URL/pub/states")
    if [ "$ret_code" -lt 400 ]; then
        echo "Done. Thank you!"
    fi

    rm "$TMPFILE"
fi
