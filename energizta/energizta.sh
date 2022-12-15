#!/bin/bash

### Usage: energizta.sh [--stresstest] [--stressfile file.txt] [--interval 5] [--warmup 20] [--duration 60]...
###
### Main options:
###   --interval INTERVAL   Measure server state each INTERVAL seconds (default 5)
###   --duration DURATION   Stop each stresstest after DURATION seconds (default 60)
###   --manual-input        Ask the user to enter power metrics manually (from a Wattmeter…)
###   --once                Do not loop, print one state and exit
###
### Stresstest options :
###   --stresstest          Run a stresstest
###   --stressfile FILEPATH Load alternative stress tests commands from a file instead of default stresstest
###   --warmup WARMUP       Wait WARMUP seconds after lauching a stresstest before measuring state (default 20)
###
### Display options:
###   --debug               Display debug outputs
###   --continuous          Display the current state every INTERVAL seconds instead of an average state every DURATION seconds
###   --energy-only         Only displays energy variables instead of global state (load, cpu, etc.)
###   --with_timestamp      Include timestamp in displayed variables
###   --with_date           Include datetime in displayed variables
###
### Misc options :
###   --force-without-root  Force the script to run with current user
###   --help                Display this help
###
### This script need to be run as root because RAPL and DCMI power metrics are only accessible by root.
###

# IDEAS :
# - Allow to have an "additionnal facts" option to run a script that will get more facts
# - Test and suggest to install ipmi-dcmi (freeipmi-tools)
# - Test and suggest to install ipmitool


VERSION="0.1a"

if ! ((BASH_VERSINFO[0] >= 4)); then
    >&2 echo "This script needs to be run with bash >= 4."
    exit 1
fi

if hostnamectl status | grep -q 'Chassis: vm'; then
    >&2 echo "This script does not work on virtual servers."
    exit 1
fi

usage () {
    sed -rn 's/^### ?//;T;p' "$0"
    echo "v$VERSION"
}

debug () {
    if $DEBUG; then
        echo "-- DEBUG: $1"
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
HOST_ID="$(lsblk -o UUID,MOUNTPOINT | grep ' /$' -m 1 | cut -d ' ' -f 1)"

while [ -n "$1" ]; do
    case $1 in
        --interval) shift; INTERVAL=$1 ;;
        --duration) shift; DURATION=$1 ;;
        --once) ONCE=true ;;
        --manual-input) MANUAL_INPUT=true ;;
        --ipmi-sensor-id) shift; IPMI_SENSOR_ID=$1 ;;

        --stresstest) STRESSTEST=true ;;
        --stressfile) shift; STRESSTEST=true; STRESSFILE=$1 ;;
        --warmup) shift; WARMUP=$1 ;;

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

# This command can hangs indefinitely so we have to test it with timeout
dcmi=$(timeout 1 /usr/sbin/ipmi-dcmi --get-system-power-statistics 2>/dev/null)
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
    IPMI_SENSOR_ID=$(timeout 10 ipmitool sensor 2>/dev/null | grep Watt | tail -n 1 | sed 's/  .*//g')
    if [ -n "$IPMI_SENSOR_ID" ]; then
        debug "Found IPMI sensor id $IPMI_SENSOR_ID"
    fi
fi

IPMI_SENSOR_NAME=$(echo "$IPMI_SENSOR_ID" | tr '[:upper:]' '[:lower:]' | sed 's/ /_/g')

if $STRESSTEST && $ONCE; then
    >&2 echo "You cannot use --once and --stresstest together."
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
    stresstests="""
sleep 120
stress-ng -q --cpu 1
stress-ng -q --cpu 4
stress-ng -q --cpu 8
"""
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
        # shellcheck disable=SC2207
        meminfo=( $(grep -E 'MemTotal|MemFree|Buffers|Cached|Shmem|SReclaimable|SUnreclaim' /proc/meminfo |awk '{print $1 " " $2}' |tr '\n' ' ' |tr -d ':' |awk '{ printf("%i %i %i %i %i %i %i", $2, $4, $6, $8, $10, $12, $14) }') )
        state[mem_total_MB]=$((meminfo[0] / 1024))
        state[mem_free_MB]=$((meminfo[1] / 1024))
        state[mem_used_MB]=$(((meminfo[0] - meminfo[1] - meminfo[2] - meminfo[3]) / 1024)) # total - free - buffer - cache

        # Diskstats
        if [ -f "/proc/diskstats" ]; then
            DISKSTATS="$(cat /proc/diskstats)"
            for dev in /sys/block/*; do
                dev="${dev##*/}"
                if [ -L "/sys/block/$dev/device" ]; then
                    state[_${dev}_read]=$(echo "$DISKSTATS" | grep " $dev " | awk '{print $4}')
                    state[_${dev}_write]=$(echo "$DISKSTATS" | grep " $dev " | awk '{print $8}')
                    #state[_${dev}_sectors_read]=$(echo "$DISKSTATS" | grep " $dev " | awk '{print $16}')
                    #state[_${dev}_sectors_write]=$(echo "$DISKSTATS" | grep " $dev " | awk '{print $10}')
                    state[_${dev}_time_io]=$(echo "$DISKSTATS" | grep " $dev " | awk '{print $13}')
                    if [ "$interval_s" -gt 0 ]; then
                        state[${dev}_read_bps]=$(((${state[_${dev}_read]} - ${last_state[_${dev}_read]}) / interval_s))
                        state[${dev}_write_bps]=$(((${state[_${dev}_write]} - ${last_state[_${dev}_write]}) / interval_s))
                        state[_${dev}_delta_time_io]=$((${state[_${dev}_time_io]} - ${last_state[_${dev}_time_io]}))
                        state[${dev}_pct_busy]=$((100 * ${state[_${dev}_delta_time_io]} / (interval_us / 1000)))
                    fi
                fi
            done
        fi
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
                state[rapl_total_watt]=$((state[rapl_total_watt] + (delta_uj / (interval_us))))
                state[_rapl_nb_src]=$((state[rapl_nb_src] + 1))
            fi

        done
    fi

    # DCMI
    if $DCMI; then
        dcmi=$(timeout .3 /usr/sbin/ipmi-dcmi --get-system-power-statistics 2>/dev/null)
        if echo "$dcmi" | grep -q 'Active$'; then
            state[dcmi_cur_watt]=$(echo "$dcmi" | grep 'Current Power' | awk '{print $4}')
        fi
    fi

    # IPMITOOL
    if [ -n "$IPMI_SENSOR_ID" ]; then
        ipmi_watt=$(timeout 3 ipmitool sdr get "$IPMI_SENSOR_ID" | grep 'Sensor Reading' | grep -Eo '[0-9]+' | head -n 1)
        if [ -n "$ipmi_watt" ]; then
            state[ipmi_${IPMI_SENSOR_NAME}_watt]=$ipmi_watt
        fi
    fi


    state_string=$(declare -p state)
    eval "declare -gA last_state=${state_string#*=}"
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
    (
    echo "{"
    $ENERGY_ONLY || echo "\"host\": \"$HOST_ID\","
    echo "\"interval_us\": ${state[interval_us]},"
    [ -n "${state[timestamp]}" ] && echo "\"timestamp\": ${state[timestamp]},"
    [ -n "${state[date]}" ] && echo "\"date\": \"${state[date]}\","
    [ -n "${state[duration_us]}" ] && echo "\"duration_us\": ${state[duration_us]},"
    [ -n "${state[nb_states]}" ] && echo "\"nb_states\": ${state[nb_states]},"
    for j in "${!state[@]}"; do
        if [[ ! "$j" == _* ]] && [[ $j =~ ([a-z0-9]_(pct_busy|read_bps|write_bps)|cpu_[a-z_]|mem_[a-z_]|load1|sensors_coretemp) ]]; then
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
            debug "$(print_state)"
        fi
        n=$((n+1))
    done

    if ! $CONTINUOUS; then
        avg_state_string=$(declare -p avg_state)
        eval "declare -gA state=${avg_state_string#*=}"
        get_manual_input
        print_state
        unset avg_state
        declare -gA avg_state
    fi
}

if $STRESSTEST; then
    # We don't want to leave a stress test running after this script
    trap '[ -n "$(jobs -p)" ] && kill "$(jobs -p)"' EXIT

    echo "$stresstests" | while IFS= read -r stresstest ; do
        if [ -n "$stresstest" ]; then
            debug "Running \"$stresstest\" for $((DURATION)) seconds"
            $stresstest > /dev/null &
            pid=$!

            if ! ps -p $pid > /dev/null; then
                echo "$stresstest has failed"
                break
            fi

            debug "-- Warming up for $WARMUP seconds…"
            sleep "$WARMUP"

            debug "-- Starting to get states…"
            get_states

            kill $pid > /dev/null 2>&1
            echo ""
        fi
    done
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
