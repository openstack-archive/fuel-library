#!/bin/bash
for localaddr in $(cat /tmp/qpid-endpoints.txt); do
	for remoteaddr in $(cat /tmp/qpid-endpoints.txt) ; do
		if [ $localaddr != $remoteaddr  ] ; then
			qpid-route -d dynamic add $localaddr $remoteaddr amq.direct
			qpid-route -d dynamic add $localaddr $remoteaddr amq.fanout
			qpid-route -d dynamic add $localaddr $remoteaddr qmf.default.topic
			qpid-route -d dynamic add $localaddr $remoteaddr qmf.default.direct
		fi
	done
done
exit 0
