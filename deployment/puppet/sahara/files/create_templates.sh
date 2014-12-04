#!/bin/bash -x
. /root/openrc

network_provider=$1
plugin=$2

case $network_provider in
   neutron)
     FLOATING_IP_POOL=$(nova net-list | grep -e "net04_ext" | awk '{print $2}')
     PRIVATE_NETWORK_ID=$(nova net-list | grep -e "net04\ " | awk '{print $2}')
     NEUTRON_MANAGEMENT_NETWORK="\"neutron_management_network\": \"$PRIVATE_NETWORK_ID\","
     ;;
   nova)
     FLOATING_IP_POOL=nova
     NEUTRON_MANAGEMENT_NETWORK=""
     ;;
   *)
     echo "Undefined network provider. Skip creating Sahara templates."
     exit 0
     ;;
esac
tmp_file=$(mktemp)

case $plugin in
   vanilla)
     # create vanilla ng templates
     sed "s/FLOATING_IP_POOL/$FLOATING_IP_POOL/g" ng_tmpl_vanilla_master.json > $tmp_file
     van_master_template_id=$(sahara node-group-template-create --json $tmp_file | grep ' id ' | awk '{print $4}')
     sed "s/FLOATING_IP_POOL/$FLOATING_IP_POOL/g" ng_tmpl_vanilla_worker.json > $tmp_file
     van_worker_template_id=$(sahara node-group-template-create --json $tmp_file | grep ' id ' | awk '{print $4}')
     # create vanilla cluster tempate
     sed -e "s/MASTER_NG_TEMPLATE/$van_master_template_id/g" \
     -e "s/WORKER_NG_TEMPLATE/$van_worker_template_id/g" \
     -e "s/NEUTRON_MANAGEMENT_NETWORK/$NEUTRON_MANAGEMENT_NETWORK/g" cl_tmpl_vanilla.json > $tmp_file
     sahara cluster-template-create --json $tmp_file 1>/dev/null
     ;;
   hdp)
     # create hdp ng templates
     sed "s/FLOATING_IP_POOL/$FLOATING_IP_POOL/g" ng_tmpl_hdp_manager.json > $tmp_file
     hdp_manager_template_id=$(sahara node-group-template-create --json $tmp_file | grep ' id ' | awk '{print $4}')

     sed "s/FLOATING_IP_POOL/$FLOATING_IP_POOL/g" ng_tmpl_hdp_master.json > $tmp_file
     hdp_master_template_id=$(sahara node-group-template-create --json $tmp_file | grep ' id ' | awk '{print $4}')

     sed "s/FLOATING_IP_POOL/$FLOATING_IP_POOL/g" ng_tmpl_hdp_worker.json > $tmp_file
     hdp_worker_template_id=$(sahara node-group-template-create --json $tmp_file | grep ' id ' | awk '{print $4}')
     # create hdp cluster template
     sed -e "s/MANAGER_NG_TEMPLATE/$hdp_manager_template_id/g" \
     -e "s/MASTER_NG_TEMPLATE/$hdp_master_template_id/g" \
     -e "s/WORKER_NG_TEMPLATE/$hdp_worker_template_id/g" \
     -e "s/NEUTRON_MANAGEMENT_NETWORK/$NEUTRON_MANAGEMENT_NETWORK/g" cl_tmpl_hdp.json > $tmp_file
     sahara cluster-template-create --json $tmp_file 1>/dev/null
     ;;
   cdh)
     # create cdh ng templates
     sed "s/FLOATING_IP_POOL/$FLOATING_IP_POOL/g" ng_tmpl_cdh_manager.json > $tmp_file
     cdh_manager_template_id=$(sahara node-group-template-create --json $tmp_file | grep ' id ' | awk '{print $4}')

     sed "s/FLOATING_IP_POOL/$FLOATING_IP_POOL/g" ng_tmpl_cdh_master.json > $tmp_file
     cdh_master_template_id=$(sahara node-group-template-create --json $tmp_file | grep ' id ' | awk '{print $4}')

     sed "s/FLOATING_IP_POOL/$FLOATING_IP_POOL/g" ng_tmpl_cdh_worker.json > $tmp_file
     cdh_worker_template_id=$(sahara node-group-template-create --json $tmp_file | grep ' id ' | awk '{print $4}')
     # create cdh cluster template
     sed -e "s/MANAGER_NG_TEMPLATE/$cdh_manager_template_id/g" \
     -e "s/MASTER_NG_TEMPLATE/$cdh_master_template_id/g" \
     -e "s/WORKER_NG_TEMPLATE/$cdh_worker_template_id/g" \
     -e "s/NEUTRON_MANAGEMENT_NETWORK/$NEUTRON_MANAGEMENT_NETWORK/g" cl_tmpl_cdh.json > $tmp_file
     sahara cluster-template-create --json $tmp_file 1>/dev/null
     ;;
   *)
     echo "Unknown plugin. Skip creating templates."
     ;;
esac

rm $tmp_file
exit 0
