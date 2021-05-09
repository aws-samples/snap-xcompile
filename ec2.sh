#!/bin/bash

set -euf -o pipefail

log_num=-1
log_start=-1
log_end=-1
log_delay=0.02
log_file='log.txt'


ec2_id=$(aws ec2 run-instances \
					--image-id ami-087fa126bfdebc5c3 \
					--instance-type t4g.micro \
					--key-name ec2_keypair \
					--security-group-ids sg-0fc6a4c88652bc982 \
					--user-data file://delete_me.sh \
					--query "Instances[0].InstanceId" \
					--output text)


while true; do
	aws ec2 get-console-output \
    --instance-id $ec2_id \
    --latest \
    --query "Output" \
    --output text > $log_file

  num=$(wc -l $log_file | awk '{ print $1 }')
  # echo "#lines in output: $num"

	if [[ $num -le 1 ]]; then
		echo -n "."
	else
		start=$(grep -Eo '\[\s*([0-9]+\.[0-9]+)\]' $log_file | head -n 1 | sed 's/[][]//g' | xargs)
		end=$(grep -Eo '\[\s*([0-9]+\.[0-9]+)\]' $log_file | tail -n 1 | sed 's/[][]//g' | xargs)

		# echo "Start of output: $start"
		# echo "End of output: $end"
		# echo "----------------"
		# echo "Current start: $log_start"
		# echo "Current end: $log_end"

		# if [[ $log_start == $start ]] && [[ $log_end == $end ]]; then
		if [[ $log_num == $num ]]; then
			echo -n "."
			continue
		elif [[ $start > $log_end ]]; then
			log_start=$start
		else
			log_start=$log_end
		fi

		log_end=$end
		log_num=$num
		# echo "Updated start: $log_ start"
		# echo "Updated end: $log_end"

		while IFS= read -r line; do
			ts=$(echo $line | grep -Eo '\[\s*([0-9]+\.[0-9]+)\]' | sed 's/[][]//g' | xargs || true)
			# echo "Current timestamp: $ts"

			if [[ ( -z $ts ) || ( $log_start < $ts && $ts < $log_end ) ]]; then
				echo $line
				sleep $log_delay
			fi
		done < $log_file
	fi
	sleep 1
done


rm $log_file
