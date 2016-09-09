#!/bin/bash
for i in `fuel2 release list | grep -e Ubuntu | grep -v unavailable | awk '{ print $2 }'`; do
    graph_types=`ls /etc/fuel/graphs/`
    # TODO(sbog): currently we can't list graph types for a release, so we
    # can't make this idempotent. As it will be fixed, let's implement
    # idempotent behavior here.
    for graph_type in ${graph_types}; do
        fuel2 graph upload -r$i -t ${graph_type} -d /etc/fuel/graphs/${graph_type}/
        COMMAND_RUN=$?
        if [[ $COMMAND_RUN -eq 1 ]];
        then
            exit 1
        fi
    done
    existing_releases=`fuel2 sequence list | grep deploy-changes | awk '{ print $4 }'`
    if ! [[ ${existing_releases[*]} =~ "$i" ]]
    then
        fuel2 sequence create -r$i -n deploy-changes -t net-verification deletion provision deploy
        COMMAND_RUN=$?
        if [[ $COMMAND_RUN -eq 1 ]];
        then
            exit 1
        fi
    fi
done
