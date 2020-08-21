#!/bin/bash
function get_bytes {
	interface=$(ip route get 8.8.8.8 2>/dev/null| awk '{print $5}')
	line=$(grep $interface /proc/net/dev | cut -d ':' -f 2 | awk '{print "received_bytes="$1, "transmitted_bytes="$9}')
	eval $line
	now=$(date +%s%N)
}

function get_velocity {
	value=$1
	old_value=$2
	now=$3

	timediff=$(($now - $old_time))
	velKB=$(echo "1000000000*($value-$old_value)/1024/$timediff" | bc)
	if test "$velKB" -gt 1024
	then
		echo $(echo "scale=2; $velKB/1024" | bc)MB/s
	else
		echo ${velKB}KB/s
	fi
}

get_bytes
old_received_bytes=$received_bytes
old_transmitted_bytes=$transmitted_bytes
old_time=$now

print_volume() {
	volume="$(amixer get Master | tail -n1 | sed -r 's/.*\[(.*)%\].*/\1/')"
	echo -e "Vol:${volume}"
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

	#echo -e "Mem:${memused}M"
}

print_date(){
	date '+%Y年%m月%d日 %H:%M'
}

get_bytes
vel_recv=$(get_velocity $received_bytes $old_received_bytes $now)
vel_trans=$(get_velocity $transmitted_bytes $old_transmitted_bytes $now)

xsetroot -name " $(print_mem)  ⬇️$vel_recv ⬆️$vel_trans  $(print_volume)%  $(print_date)"

old_received_bytes=$received_bytes
old_transmitted_bytes=$transmitted_bytes
old_time=$now

exit 0
