#!/usr/bin/env bash

trap "exit" INT

# global variables
workload_dir="workloads"
rocksdb_dir="/mnt/kvs/scratch/rocksdb"
pebblesdb_dir="/mnt/kvs/scratch/pebblesdb"

# usage function
function usage {
    echo "Usage: $0 <arg>"
    echo "arg: help|h"
    echo "arg: load [dbs] <record size> <record count>"
    echo "arg: get [dbs] <record count>"
    echo "arg: get_update [dbs] <record count>"
    echo "arg: scan [dbs] <length> <record count>"
    echo "arg: aging [dbs] <record count>"
}

function execute {
    local type=$1
    local db=$2
    local workload_file=$3
    local additional_args=$4

    ./bin/ycsb $type $db -s -P $workload_file $additional_args #  2>/dev/null \
        # | grep -E "RunTime|Throughput|AverageLatency|50thPercentileLatency|95thPercentileLatency|99thPercentileLatency|99.99PercentileLatency" \
        # | grep -Ev "CLEANUP" \
        # | awk '{print $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16}'
}

function validate_record_count {
    local record_count=$1

    if [ ! -d "$workload_dir/$record_count" ]; then
        echo Invalid record count $record_count
        echo Valid record counts are: $(ls $workload_dir | grep -E "^[0-9]+M$" | tr '\n' ' '| sort)
        exit 1
    fi
}

function value_in_list {
    local value=$1
    local list=$2

    for item in $list; do
        if [ "$item" = "$value" ]; then
            return 0
        fi
    done

    return 1
}

function load {
    local dbs=$1
    local record_size=${2:-64}
    local record_count=${3:-1M}

    validate_record_count $record_count

    local file_prefix=$workload_dir/$record_count/load-

    local valid_sizes=$(ls $file_prefix* | awk -F'-' '{print $NF}' | sort -n | uniq)

    value_in_list $record_size "$valid_sizes"
    local size_is_valid=$?

    if [ $size_is_valid -ne 0 ]; then
        echo Invalid record size $record_size
        echo Valid record sizes are: $valid_sizes for record count $record_count
        exit 0
    fi

    local workload_file="$file_prefix$record_size"

    # /mnt/kvs/scratch/clean.sh
    for db in $dbs; do
        # echo Executing load on $db with record size $record_size and record count $record_count
        execute load $db $workload_file "-p rocksdb.dir=$rocksdb_dir -p pebblesdb.path=$pebblesdb_dir" # -p rocksdb.optionsfile=/mnt/kvs/ycsb/YCSB-0.15.0/rocksdbconfig.ini" # rocksdb args are harmless to other dbs
        echo
    done
}

function get {
    local dbs=$1
    local record_count=${2:-1M}

    validate_record_count $record_count

    local workload_file="$workload_dir/$record_count/get-50K"

    for db in $dbs; do
        # echo Executing get on $db with record count $record_count
        execute run $db $workload_file "-p rocksdb.dir=$rocksdb_dir -p pebblesdb.path=$pebblesdb_dir"
        echo
    done
}

function get_update {
    local dbs=$1
    local record_count=${2:-1M}

    validate_record_count $record_count

    local workload_file="$workload_dir/$record_count/get-up-50K"

    for db in $dbs; do
        # echo Executing get_update on $db with record count $record_count
        execute run $db $workload_file "-p rocksdb.dir=$rocksdb_dir -p pebblesdb.path=$pebblesdb_dir"
        echo
    done
}

function scan {
    local dbs=$1
    local length=${2:-100}
    local record_count=${3:-1M}

    validate_record_count $record_count

    local file_prefix=$workload_dir/$record_count/scan-

    local valid_lengths=$(ls $file_prefix* | awk -F'-' '{print $NF}' | sort -n | uniq)
    
    value_in_list $length "$valid_lengths"
    local length_is_valid=$?

    if [ $length_is_valid -ne 0 ]; then
        echo Invalid scan length $length
        echo Valid scan lengths are: $valid_lengths for record count $record_count
        exit 0
    fi

    local workload_file="$file_prefix$length"

    for db in $dbs; do
        # echo Executing scan on $db with length $length and record count $record_count
        execute run $db $workload_file "-p rocksdb.dir=$rocksdb_dir -p pebblesdb.path=$pebblesdb_dir"
        echo
    done
}

function aging {
    local dbs=$1
    local record_count=${2:-1M}

    validate_record_count $record_count

    local workload_file="$workload_dir/$record_count/aging"

    for db in $dbs; do
        # echo Executing aging on $db with record count $record_count
        execute run $db $workload_file "-p rocksdb.dir=$rocksdb_dir -p pebblesdb.path=$pebblesdb_dir"
        echo
    done
}

# usage
if [ $# -lt 2 ]; then
    usage
    exit 1
fi

if [ $1 = "help" ] || [ $1 = "h" ]; then
    usage
    exit 0
fi

# load
if [ $1 = "load" ]; then
    load "$2" $3 $4
    exit 0
fi

# get
if [ $1 = "get" ]; then
    get "$2" $3
    exit 0
fi

# get_update
if [ $1 = "get_update" ]; then
    get_update "$2" $3
    exit 0
fi

# scan
if [ $1 = "scan" ]; then
    scan "$2" $3 $4
    exit 0
fi

# aging
if [ $1 = "aging" ]; then
    aging "$2" $3
    exit 0
fi





