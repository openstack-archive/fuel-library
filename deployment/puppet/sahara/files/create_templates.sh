#!/bin/bash -x
. /root/openrc
case $1 in
   neutron)
     FLOATING_IP_POOL=$(nova net-list | grep -e "net04_ext" | awk '{print $2}')
     PRIVATE_NETWORK_ID=$(nova net-list | grep -e "net04\ " | awk '{print $2}')
     ;;
   nova)
     FLOATING_IP_POOL=nova
     PRIVATE_NETWORK_ID=$(nova net-list | grep -e "novanetwork" | awk '{print $2}')
     ;;
   *)
     echo "Undefined network provider. Skip creating Sahara templates."
     exit 0
     ;;
esac
tmp_file=$(mktemp)

# create vanilla ng templates
sed "s/FLOATING_IP_POOL/$FLOATING_IP_POOL/g" ng_tmpl_vanilla_master.json > $tmp_file
van_master_template_id=$(sahara node-group-template-create --json $tmp_file | grep ' id ' | awk '{print $4}')

sed "s/FLOATING_IP_POOL/$FLOATING_IP_POOL/g" ng_tmpl_vanilla_worker.json > $tmp_file
van_worker_template_id=$(sahara node-group-template-create --json $tmp_file | grep ' id ' | awk '{print $4}')

# create hdp ng templates
sed "s/FLOATING_IP_POOL/$FLOATING_IP_POOL/g" ng_tmpl_hdp_manager.json > $tmp_file
hdp_manager_template_id=$(sahara node-group-template-create --json $tmp_file | grep ' id ' | awk '{print $4}')

sed "s/FLOATING_IP_POOL/$FLOATING_IP_POOL/g" ng_tmpl_hdp_master.json > $tmp_file
hdp_master_template_id=$(sahara node-group-template-create --json $tmp_file | grep ' id ' | awk '{print $4}')

sed "s/FLOATING_IP_POOL/$FLOATING_IP_POOL/g" ng_tmpl_hdp_worker.json > $tmp_file
hdp_worker_template_id=$(sahara node-group-template-create --json $tmp_file | grep ' id ' | awk '{print $4}')

# create vanilla cluster tempate
sed -e "s/MASTER_NG_TEMPLATE/$van_master_template_id/g" \
    -e "s/WORKER_NG_TEMPLATE/$van_worker_template_id/g" \
    -e "s/PRIVATE_NETWORK/$PRIVATE_NETWORK_ID/g" cl_tmpl_vanilla.json > $tmp_file
sahara cluster-template-create --json $tmp_file

# create hdp cluster_template
sed -e "s/MANAGER_NG_TEMPLATE/$hdp_manager_template_id/g" \
    -e "s/MASTER_NG_TEMPLATE/$hdp_master_template_id/g" \
    -e "s/WORKER_NG_TEMPLATE/$hdp_worker_template_id/g" \
    -e "s/PRIVATE_NETWORK/$PRIVATE_NETWORK_ID/g" cl_tmpl_hdp.json > $tmp_file
sahara cluster-template-create --json $tmp_file

echo "true" > templates_installed
rm $tmp_file
