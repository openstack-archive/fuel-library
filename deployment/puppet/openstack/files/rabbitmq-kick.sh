#!/bin/bash

# Gracefully remove a node from RabbitMQ cluster
# Assume that the given node is not running the mnesia

node_name=`echo $1 | awk -F "." '{print $1}'`
node_to_remove="rabbit@${node_name}"
this_node=`hostname -s`

# Exit on empty names
test -n ${node_name} || exit 1

# Exit if trying to remove itself
[[ "${this_node}" -ne "${node_name}" ]] || exit 1

# Exit if already removed
rc=`rabbitmqctl eval "mnesia_lib:val({current,db_nodes})." | grep -q "${node_to_remove}"`
[[ $rc -eq 0 ]] || exit 1

rabbitmqctl eval "disconnect_node(list_to_atom(\"${node_to_remove}\"))."
rabbitmqctl forget_cluster_node "${node_to_remove}"
