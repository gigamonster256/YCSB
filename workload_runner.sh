#!/usr/bin/env bash

trap "exit" INT

# record_counts="1M 10M 50M 100M"
record_counts="1M"
# load_sizes="64 256 1k 4k"
load_sizes="64"
# 512 1k"
# 512 1k 4k"
# scan_lengths="100"
# scan_lengths="50 100 500"
scan_lengths="50 100"
aging_rounds=3
do_compaction=0
do_gets=1
do_get_update=1
aging_last=0

results_dir="results/intial_1M"
# dbs="snap3db"
# dbs="mixdb rocksdb wisckey snap3db"
dbs="snapdb"
# snapdb wisckey rocksdb snap3db mixdb"

if [ ! -d "$results_dir" ]; then
	mkdir -p $results_dir
fi

for record_count in $record_counts; do
	for load_size in $load_sizes; do
		echo "Cleaning old databases"
		/mnt/kvs/scratch/clean.sh
		run_name="loads with record size $load_size and record count $record_count"
		echo "Running $run_name"
		for db in $dbs; do
			beginning_writes=$(cat /sys/block/nvme1n1/stat | awk '{print $7}')
			output_file="$results_dir/load-$load_size-$record_count-$db"
			/usr/bin/time -v ./benchmark.sh load $db $load_size $record_count >$output_file.csv 2>$output_file.time
			after_writes=$(cat /sys/block/nvme1n1/stat | awk '{print $7}')
			echo "Writes: $((after_writes - beginning_writes))" >>$output_file.time
		done

		# save size of dbs
		echo "Saving size of dbs"
		for db in $dbs; do
			du /mnt/kvs/scratch/$db >>$results_dir/load_size-$load_size-$record_count.txt
		done

		# save kdb size
		echo "Saving kdb size"
		du /mnt/kvs/scratch/snapdb/keydb.tkmb >>$results_dir/load_size-$load_size-$record_count.txt
		du /mnt/kvs/scratch/snap3db/keydb.tkmb >>$results_dir/load_size-$load_size-$record_count.txt

		# run aging last if set to 1
		if [ $aging_last -eq 0 ]; then
			for aging_round in $(seq 1 $aging_rounds); do
				run_name="aging with record count $record_count" # load_size is implicit based on what was last loaded
				echo "Running $run_name"
				for db in $dbs; do
					output_file="$results_dir/aging-$load_size-$record_count-$aging_round-$db"
					beginning_writes=$(cat /sys/block/nvme1n1/stat | awk '{print $7}')
					/usr/bin/time -v ./benchmark.sh aging $db $record_count >$output_file.csv 2>$output_file.time
					after_writes=$(cat /sys/block/nvme1n1/stat | awk '{print $7}')
					echo "Writes: $((after_writes - beginning_writes))" >>$output_file.time
				done

				# # dump garbage collection stats
				# echo "Saving garbage collection stats"
				# /mnt/kvs/wisckey_caleb/test/test_snap d /mnt/kvs/scratch/snapdb &>$results_dir/gc-$load_size-$record_count-$aging_round.txt

				# save size of db
				echo "Saving size of dbs"
				for db in $dbs; do
					du /mnt/kvs/scratch/$db >>$results_dir/aging_size-$load_size-$record_count-$aging_round.txt
				done
			done
		fi

		# run compaction on snapdb if set to 1
		if [ $do_compaction -eq 1 ]; then
			echo "Running compaction"
			/usr/bin/time -v /mnt/kvs/wisckey_caleb/test/test_snap c /mnt/kvs/scratch/snapdb &>$results_dir/compact-$load_size-$record_count.time

			# print size of dbs
			echo "Saving size of dbs"
			for db in $dbs; do
				du /mnt/kvs/scratch/$db >>$results_dir/compact_size-$load_size-$record_count.txt
			done
		fi

		# run gets
		if [ $do_gets -eq 1 ]; then
			run_name="gets with record count $record_count" # load_size is implicit based on what was last loaded
			echo "Running $run_name"
			for db in $dbs; do
				output_file="$results_dir/get-$load_size-$record_count-$db"
				beginning_writes=$(cat /sys/block/nvme1n1/stat | awk '{print $7}')
				/usr/bin/time -v ./benchmark.sh get $db $record_count >$output_file.csv 2>$output_file.time
				after_writes=$(cat /sys/block/nvme1n1/stat | awk '{print $7}')
				echo "Writes: $((after_writes - beginning_writes))" >>$output_file.time
			done
		fi

		if [ $do_get_update -eq 1 ]; then
			run_name="get_updates with record count $record_count" # load_size is implicit based on what was last loaded
			echo "Running $run_name"
			for db in $dbs; do
				output_file="$results_dir/get_update-$load_size-$record_count-$db"
				beginning_writes=$(cat /sys/block/nvme1n1/stat | awk '{print $7}')
				/usr/bin/time -v ./benchmark.sh get_update $db $record_count >$output_file.csv 2>$output_file.time
				after_writes=$(cat /sys/block/nvme1n1/stat | awk '{print $7}')
				echo "Writes: $((after_writes - beginning_writes))" >>$output_file.time
			done
		fi

		# run scans
		for scan_length in $scan_lengths; do
			run_name="scans with length $scan_length and record count $record_count" # load_size is implicit based on what was last loaded
			echo "Running $run_name"
			for db in $dbs; do
				output_file="$results_dir/scan-$load_size-$scan_length-$record_count-$db"
				beginning_writes=$(cat /sys/block/nvme1n1/stat | awk '{print $7}')
				/usr/bin/time -v ./benchmark.sh scan $db $scan_length $record_count >$output_file.csv 2>$output_file.time
				after_writes=$(cat /sys/block/nvme1n1/stat | awk '{print $7}')
				echo "Writes: $((after_writes - beginning_writes))" >>$output_file.time
			done
		done

		# run aging last if set to 1
		if [ $aging_last -eq 1 ]; then
			for aging_round in $(seq 1 $aging_rounds); do
				run_name="aging with record count $record_count"
				echo "Running $run_name"
				for db in $dbs; do
					output_file="$results_dir/aging-$load_size-$record_count-$aging_round-$db"
					beginning_writes=$(cat /sys/block/nvme1n1/stat | awk '{print $7}')
					/usr/bin/time -v ./benchmark.sh aging $db $record_count >$output_file.csv 2>$output_file.time
					after_writes=$(cat /sys/block/nvme1n1/stat | awk '{print $7}')
					echo "Writes: $((after_writes - beginning_writes))" >>$output_file.time
				done

				# # dump garbage collection stats
				# echo "Saving garbage collection stats"
				# /mnt/kvs/wisckey_caleb/test/test_snap d /mnt/kvs/scratch/snapdb &>$results_dir/gc-$load_size-$record_count-$aging_round.txt

				# save size of db
				echo "Saving size of dbs"
				for db in $dbs; do
					du /mnt/kvs/scratch/$db >>$results_dir/aging_size-$load_size-$record_count-$aging_round.txt
				done
			done
		fi
	done
done
