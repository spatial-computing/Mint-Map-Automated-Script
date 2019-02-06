#!/usr/bin/env bash

check_idle_cpu() {
	if [[ -z "$MIN_TRHEAD_NUM" ]]; then
		MIN_TRHEAD_NUM=4
	fi
	uname=$(uname -av | awk '{print $1}')
	if [[ "$uname" == "Linux" ]]; then
		COMMAND_EXIST=$(command -v mpstat)
		if [[ -z "$COMMAND_EXIST" ]]; then
			>&2 echo "Please install sysstat first"
			exit 1
		fi

		oldIFS=$IFS

		>&2 echo "\n\n"
		>&2 mpstat -P ALL
		>&2 echo "\n\n"

		CPU_INFO=$(mpstat -P ALL -u | tail -n +5 | awk '{print int(100-$NF)}')
		IFS=$'\n'
		CPU_USAGE=($CPU_INFO)
		let idle_count=0
		for usage_percent in ${CPU_USAGE[@]}; do
			if [[ $usage_percent -lt $USAGE_UNDER_PERCENTAGE_CONSIDERED_AS_IDLE ]]; then
				idle_count=$((idle_count+1))
			fi
		done

		THREADS_NUM=$idle_count
		
		if [[ $THREADS_NUM -lt $MIN_TRHEAD_NUM ]]; then
			THREADS_NUM=$MIN_TRHEAD_NUM
		fi
		
		if [[ $THREADS_NUM -lt 1 ]]; then
			THREADS_NUM=1
		fi

		IFS=$oldIFS
	elif [[ "$uname" == "Darwin" ]]; then
		THREADS_NUM=$(sysctl -n hw.ncpu)
	fi
	echo "THREADS_NUM: $THREADS_NUM"
}