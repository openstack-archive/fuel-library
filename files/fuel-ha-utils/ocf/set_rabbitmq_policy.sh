# Set your RabbitMQ cluster policy here, for example:
# ${OCF_RESKEY_ctl} set_policy ha-all "." '{"ha-mode":"all", "ha-sync-mode":"automatic"}' --apply-to all --priority 0

if [ "${OCF_RESKEY_enable_rpc_ha}" = 'true' ] ; then
    ocf_log info "${LH} Setting HA policy for all queues"
    ${OCF_RESKEY_ctl} set_policy ha-all "." '{"ha-mode":"all", "ha-sync-mode":"automatic"}' --apply-to all --priority 0
    ${OCF_RESKEY_ctl} set_policy heat_rpc_expire "^heat-engine-listener\\." '{"expires":3600000, "ha-mode":"all", "ha-sync-mode":"automatic"}' --apply-to all --priority 1
    ${OCF_RESKEY_ctl} set_policy results_expire "^results\\." '{"expires":3600000, "ha-mode":"all", "ha-sync-mode":"automatic"}' --apply-to all --priority 1
    ${OCF_RESKEY_ctl} set_policy tasks_expire "^tasks\\." '{"expires":3600000, "ha-mode":"all", "ha-sync-mode":"automatic"}' --apply-to all --priority 1
else
    ocf_log info "${LH} Setting HA policy for Ceilometer queues"
    ${OCF_RESKEY_ctl} set_policy ha-notif "^(event|metering|notifications)\." '{"ha-mode":"all", "ha-sync-mode":"automatic"}' --apply-to all --priority 0
    ${OCF_RESKEY_ctl} set_policy heat_rpc_expire "^heat-engine-listener\\." '{"expires":3600000}' --apply-to all --priority 1
    ${OCF_RESKEY_ctl} set_policy results_expire "^results\\." '{"expires":3600000}' --apply-to all --priority 1
    ${OCF_RESKEY_ctl} set_policy tasks_expire "^tasks\\." '{"expires":3600000}' --apply-to all --priority 1
fi
