#!/bin/bash

# Set running environment to en_US.UTF-8
LANG=en_US.UTF-8

# From Johan Chane <johanchanex@gmail.com>
# This function parses /proc/net/dev file searching for a line containing $interface data.
# Within that line, the first and ninth numbers after ':' are respectively the received and transmited bytes.
# parameters: name_of_received_bytes, name_of_transmitted_bytes
function get_bytes {
    # Find active network interface
    #interface=$(ip route get 8.8.8.8 2>/dev/null | grep 'dev \S\+' -o | awk '{print $2}')
    local interface=$(route | grep '^default' | grep -o '[^ ]*$')
    local bytes_concat_args=$(grep ${interface:-lo} /proc/net/dev | cut -d ':' -f 2 | awk -v rb="$1" -v tb="$2" '{print rb"="$1, tb"="$9}')
    eval $bytes_concat_args
}

# Function which calculates the speed using actual and old byte number.
# Speed is shown in KByte per second when greater or equal than 1 KByte per second.
# This function should be called each second.
# parameters: value, old_value, now, old_time
function get_velocity {
    local timediff=$(($3 - $4))
    local vel_kb=$(echo "1000000000 * ($1 - $2) / 1024 / $timediff" | bc)
    if test "$vel_kb" -gt 1024; then
        echo $(echo "scale = 2; $vel_kb / 1024" | bc)MB/s
    else
        echo ${vel_kb}KB/s
    fi
}

function dwm_network_speed_record {
    get_bytes 'received_bytes' 'transmitted_bytes'
    old_received_bytes=$received_bytes
    old_transmitted_bytes=$transmitted_bytes

    old_time=$(date +%s%N)
}

function download_speed {
    get_velocity $received_bytes $old_received_bytes $now $old_time
}

function upload_speed {
    get_velocity $transmitted_bytes $old_transmitted_bytes $now $old_time
}

# The greater interval ($now - $old_time) is, the be exacter the speed is.
function dwm_network_speed {
    get_bytes 'received_bytes' 'transmitted_bytes'
    now=$(date +%s%N)

    printf "%s %s" "$(upload_speed)" "$(download_speed)"
}

dwm_battery () {
    # Change BAT1 to whatever your battery is identified as. Typically BAT0 or BAT1
    CHARGE=$(cat /sys/class/power_supply/BAT1/capacity)
    STATUS=$(cat /sys/class/power_supply/BAT1/status)

    printf "%s" "$SEP1"
    if [ "$STATUS" = "Charging" ] || [ "$STATUS" = "Full" ]; then
        if [ "$CHARGE" -le 100 ] && [ "$CHARGE" -ge 66 ]; then
            printf "󱊦 %s%% %s" "$CHARGE" "$STATUS"
        elif [ "$CHARGE" -le 66 ] && [ "$CHARGE" -ge 33 ]; then
            printf "󱊥 %s%% %s" "$CHARGE" "$STATUS"
        else
            printf "󱊤 %s%% %s" "$CHARGE" "$STATUS"
        fi
    else
        if [ "$CHARGE" -le 100 ] && [ "$CHARGE" -ge 66 ]; then
            printf "󱊣 %s%% %s" "$CHARGE" "$STATUS"
        elif [ "$CHARGE" -le 66 ] && [ "$CHARGE" -ge 33 ]; then
            printf "󱊢 %s%% %s" "$CHARGE" "$STATUS"
        else
            printf "󱊡 %s%% %s" "$CHARGE" "$STATUS"
        fi
    fi
    printf "%s\n" "$SEP2"
}

print_volume () {
    volume=$(amixer get Master | tail -n1 | sed -r "s/.*\[(.*)%\].*/\1/")
    if [ "$volume" -eq 0 ]; then
        printf "󰸈"
    elif [ "$volume" -gt 0 ] && [ "$volume" -le 33 ]; then
        printf "󰕿 %s%%" "$volume"
    elif [ "$volume" -gt 33 ] && [ "$volume" -le 66 ]; then
        printf "󰖀 %s%%" "$volume"
    else
        printf "󰕾 %s%%" "$volume"
    fi
}

print_mem(){
	memused=$(($(free -m | grep 'Mem:' | awk '{print $3}')))
	if test $[memused] -lt $[1024]
	then
		echo -e "Mem:${memused}M"
	else
		new_memused=`echo "scale=2;$memused/1024" | bc`
		echo -e "Mem:${new_memused}G"
	fi
}

print_disk(){
		diskused=$(df -h | awk '{print $5}' | sed -n '4, 1p')
		printf "󰋊:${diskused}%"
}

print_date(){
		date '+%Y年%m月%d日 %H:%M'
}

dwm_weather(){
		if [[ `curl -s "wttr.in/$LOCATION?format=1"` == *"404"* ]]; then
				printf "%s" "404"
		elif [[ `curl -s "wttr.in/$LOCATION?format=1"` == *"502"* ]]; then
				printf "%s" "502"
		elif [[ `curl -s "wttr.in/$LOCATION?format=1"` == *"500"* ]]; then
				printf "%s" "500"
		else
				printf "%s" "$(curl -s "wttr.in/$LOCATION?format=1" | sed 's/+//g')"
		fi
}

dwm_network_speed_record

xsetroot -name " $(print_mem)  $(print_disk)  $(dwm_network_speed)  $(print_volume)  [$(dwm_battery)]  $(print_date)  $(dwm_weather)"
# xsetroot -name " $(print_mem)  $(print_disk)  $vel_recv $vel_trans  $(print_volume) $(print_date)  "

exit 0
