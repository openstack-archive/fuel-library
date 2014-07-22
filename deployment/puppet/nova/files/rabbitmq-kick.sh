#!/bin/bash

node_name=`echo $1 | awk -F "." '{print $1}'`

test -n ${node_name} || exit 1


node_to_remove=rabbit@${node_name}

rabbitmqctl eval \'"mnesia_lib:del({schema,active_replicas},list_to_atom(\"${node_to_remove}\"))."\'
rabbitmqctl eval \'"mnesia_lib:del({current,db_nodes},list_to_atom(\"${node_to_remove}\"))."\'
rabbitmqctl eval \'"mnesia_lib:del({current,extra_db_nodes},list_to_atom(\"${node_to_remove}\"))."\'
rabbitmqctl forget_cluster_node ${node_to_remove}

