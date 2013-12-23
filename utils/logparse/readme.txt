This scripts helps you to parse log files found on master node
after Fuel deployment and find out which actions and resource
types did take the most time.

Run ruby parser directly
> ruby logparse.rb puppet-apply.log

Run shell helper directly on log
> sh logparse.sh puppet-apply.log

Run shell helper on unpacked Fuel snapshot to view all logs
Press Enter to view next

> sh logparse.sh fuel-snapshot-????

Run shell helper on unpacked snapshot
> sh logparse.sh fuel-snapshot-????.tgz
