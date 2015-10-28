ceilometer_config { 'DEFAULT/debug':
  before => 'Exec[ceilometer-dbsync]',
  name   => 'DEFAULT/debug',
  notify => ['Service[ceilometer-api]', 'Service[ceilometer-collector]', 'Service[ceilometer-agent-central]', 'Service[ceilometer-alarm-evaluator]', 'Service[ceilometer-alarm-notifier]', 'Service[ceilometer-agent-notification]'],
  value  => 'false',
}

ceilometer_config { 'DEFAULT/http_timeout':
  before => 'Exec[ceilometer-dbsync]',
  name   => 'DEFAULT/http_timeout',
  notify => ['Service[ceilometer-api]', 'Service[ceilometer-collector]', 'Service[ceilometer-agent-central]', 'Service[ceilometer-alarm-evaluator]', 'Service[ceilometer-alarm-notifier]', 'Service[ceilometer-agent-notification]'],
  value  => '600',
}

ceilometer_config { 'DEFAULT/log_dir':
  before => 'Exec[ceilometer-dbsync]',
  name   => 'DEFAULT/log_dir',
  notify => ['Service[ceilometer-api]', 'Service[ceilometer-collector]', 'Service[ceilometer-agent-central]', 'Service[ceilometer-alarm-evaluator]', 'Service[ceilometer-alarm-notifier]', 'Service[ceilometer-agent-notification]'],
  value  => '/var/log/ceilometer',
}

ceilometer_config { 'DEFAULT/memcached_servers':
  ensure => 'absent',
  before => 'Exec[ceilometer-dbsync]',
  name   => 'DEFAULT/memcached_servers',
  notify => ['Service[ceilometer-api]', 'Service[ceilometer-collector]', 'Service[ceilometer-agent-central]', 'Service[ceilometer-alarm-evaluator]', 'Service[ceilometer-alarm-notifier]', 'Service[ceilometer-agent-notification]'],
}

ceilometer_config { 'DEFAULT/notification_topics':
  before => 'Exec[ceilometer-dbsync]',
  name   => 'DEFAULT/notification_topics',
  notify => ['Service[ceilometer-api]', 'Service[ceilometer-collector]', 'Service[ceilometer-agent-central]', 'Service[ceilometer-alarm-evaluator]', 'Service[ceilometer-alarm-notifier]', 'Service[ceilometer-agent-notification]'],
  value  => 'notifications',
}

ceilometer_config { 'DEFAULT/rpc_backend':
  before => 'Exec[ceilometer-dbsync]',
  name   => 'DEFAULT/rpc_backend',
  notify => ['Service[ceilometer-api]', 'Service[ceilometer-collector]', 'Service[ceilometer-agent-central]', 'Service[ceilometer-alarm-evaluator]', 'Service[ceilometer-alarm-notifier]', 'Service[ceilometer-agent-notification]'],
  value  => 'rabbit',
}

ceilometer_config { 'DEFAULT/swift_rados_backend':
  before => 'Exec[ceilometer-dbsync]',
  name   => 'DEFAULT/swift_rados_backend',
  notify => ['Service[ceilometer-api]', 'Service[ceilometer-collector]', 'Service[ceilometer-agent-central]', 'Service[ceilometer-alarm-evaluator]', 'Service[ceilometer-alarm-notifier]', 'Service[ceilometer-agent-notification]'],
  value  => 'true',
}

ceilometer_config { 'DEFAULT/syslog_log_facility':
  before => 'Exec[ceilometer-dbsync]',
  name   => 'DEFAULT/syslog_log_facility',
  notify => ['Service[ceilometer-api]', 'Service[ceilometer-collector]', 'Service[ceilometer-agent-central]', 'Service[ceilometer-alarm-evaluator]', 'Service[ceilometer-alarm-notifier]', 'Service[ceilometer-agent-notification]'],
  value  => 'LOG_LOCAL0',
}

ceilometer_config { 'DEFAULT/use_stderr':
  before => 'Exec[ceilometer-dbsync]',
  name   => 'DEFAULT/use_stderr',
  notify => ['Service[ceilometer-api]', 'Service[ceilometer-collector]', 'Service[ceilometer-agent-central]', 'Service[ceilometer-alarm-evaluator]', 'Service[ceilometer-alarm-notifier]', 'Service[ceilometer-agent-notification]'],
  value  => 'false',
}

ceilometer_config { 'DEFAULT/use_syslog':
  before => 'Exec[ceilometer-dbsync]',
  name   => 'DEFAULT/use_syslog',
  notify => ['Service[ceilometer-api]', 'Service[ceilometer-collector]', 'Service[ceilometer-agent-central]', 'Service[ceilometer-alarm-evaluator]', 'Service[ceilometer-alarm-notifier]', 'Service[ceilometer-agent-notification]'],
  value  => 'true',
}

ceilometer_config { 'DEFAULT/use_syslog_rfc_format':
  before => 'Exec[ceilometer-dbsync]',
  name   => 'DEFAULT/use_syslog_rfc_format',
  notify => ['Service[ceilometer-api]', 'Service[ceilometer-collector]', 'Service[ceilometer-agent-central]', 'Service[ceilometer-alarm-evaluator]', 'Service[ceilometer-alarm-notifier]', 'Service[ceilometer-agent-notification]'],
  value  => 'true',
}

ceilometer_config { 'DEFAULT/verbose':
  before => 'Exec[ceilometer-dbsync]',
  name   => 'DEFAULT/verbose',
  notify => ['Service[ceilometer-api]', 'Service[ceilometer-collector]', 'Service[ceilometer-agent-central]', 'Service[ceilometer-alarm-evaluator]', 'Service[ceilometer-alarm-notifier]', 'Service[ceilometer-agent-notification]'],
  value  => 'true',
}

ceilometer_config { 'alarm/evaluation_interval':
  before => 'Exec[ceilometer-dbsync]',
  name   => 'alarm/evaluation_interval',
  notify => ['Service[ceilometer-api]', 'Service[ceilometer-collector]', 'Service[ceilometer-agent-central]', 'Service[ceilometer-alarm-evaluator]', 'Service[ceilometer-alarm-notifier]', 'Service[ceilometer-agent-notification]'],
  value  => '60',
}

ceilometer_config { 'alarm/evaluation_service':
  before => 'Exec[ceilometer-dbsync]',
  name   => 'alarm/evaluation_service',
  notify => ['Service[ceilometer-api]', 'Service[ceilometer-collector]', 'Service[ceilometer-agent-central]', 'Service[ceilometer-alarm-evaluator]', 'Service[ceilometer-alarm-notifier]', 'Service[ceilometer-agent-notification]'],
  value  => 'ceilometer.alarm.service.SingletonAlarmService',
}

ceilometer_config { 'alarm/partition_rpc_topic':
  before => 'Exec[ceilometer-dbsync]',
  name   => 'alarm/partition_rpc_topic',
  notify => ['Service[ceilometer-api]', 'Service[ceilometer-collector]', 'Service[ceilometer-agent-central]', 'Service[ceilometer-alarm-evaluator]', 'Service[ceilometer-alarm-notifier]', 'Service[ceilometer-agent-notification]'],
  value  => 'alarm_partition_coordination',
}

ceilometer_config { 'alarm/record_history':
  before => 'Exec[ceilometer-dbsync]',
  name   => 'alarm/record_history',
  notify => ['Service[ceilometer-api]', 'Service[ceilometer-collector]', 'Service[ceilometer-agent-central]', 'Service[ceilometer-alarm-evaluator]', 'Service[ceilometer-alarm-notifier]', 'Service[ceilometer-agent-notification]'],
  value  => 'true',
}

ceilometer_config { 'api/host':
  before => 'Exec[ceilometer-dbsync]',
  name   => 'api/host',
  notify => ['Service[ceilometer-api]', 'Service[ceilometer-collector]', 'Service[ceilometer-agent-central]', 'Service[ceilometer-alarm-evaluator]', 'Service[ceilometer-alarm-notifier]', 'Service[ceilometer-agent-notification]'],
  value  => '192.168.0.3',
}

ceilometer_config { 'api/port':
  before => 'Exec[ceilometer-dbsync]',
  name   => 'api/port',
  notify => ['Service[ceilometer-api]', 'Service[ceilometer-collector]', 'Service[ceilometer-agent-central]', 'Service[ceilometer-alarm-evaluator]', 'Service[ceilometer-alarm-notifier]', 'Service[ceilometer-agent-notification]'],
  value  => '8777',
}

ceilometer_config { 'collector/udp_address':
  before => 'Exec[ceilometer-dbsync]',
  name   => 'collector/udp_address',
  notify => ['Service[ceilometer-api]', 'Service[ceilometer-collector]', 'Service[ceilometer-agent-central]', 'Service[ceilometer-alarm-evaluator]', 'Service[ceilometer-alarm-notifier]', 'Service[ceilometer-agent-notification]'],
  value  => '0.0.0.0',
}

ceilometer_config { 'collector/udp_port':
  before => 'Exec[ceilometer-dbsync]',
  name   => 'collector/udp_port',
  notify => ['Service[ceilometer-api]', 'Service[ceilometer-collector]', 'Service[ceilometer-agent-central]', 'Service[ceilometer-alarm-evaluator]', 'Service[ceilometer-alarm-notifier]', 'Service[ceilometer-agent-notification]'],
  value  => '4952',
}

ceilometer_config { 'database/alarm_history_time_to_live':
  before => 'Exec[ceilometer-dbsync]',
  name   => 'database/alarm_history_time_to_live',
  notify => ['Service[ceilometer-api]', 'Service[ceilometer-collector]', 'Service[ceilometer-agent-central]', 'Service[ceilometer-alarm-evaluator]', 'Service[ceilometer-alarm-notifier]', 'Service[ceilometer-agent-notification]'],
  value  => '-1',
}

ceilometer_config { 'database/connection':
  before => 'Exec[ceilometer-dbsync]',
  name   => 'database/connection',
  notify => ['Exec[ceilometer-dbsync]', 'Service[ceilometer-api]', 'Service[ceilometer-collector]', 'Service[ceilometer-agent-central]', 'Service[ceilometer-alarm-evaluator]', 'Service[ceilometer-alarm-notifier]', 'Service[ceilometer-agent-notification]'],
  secret => 'true',
  value  => 'mongodb://ceilometer:Toe5phw4@192.168.0.1/ceilometer',
}

ceilometer_config { 'database/event_time_to_live':
  before => 'Exec[ceilometer-dbsync]',
  name   => 'database/event_time_to_live',
  notify => ['Service[ceilometer-api]', 'Service[ceilometer-collector]', 'Service[ceilometer-agent-central]', 'Service[ceilometer-alarm-evaluator]', 'Service[ceilometer-alarm-notifier]', 'Service[ceilometer-agent-notification]'],
  value  => '604800',
}

ceilometer_config { 'database/metering_time_to_live':
  before => 'Exec[ceilometer-dbsync]',
  name   => 'database/metering_time_to_live',
  notify => ['Service[ceilometer-api]', 'Service[ceilometer-collector]', 'Service[ceilometer-agent-central]', 'Service[ceilometer-alarm-evaluator]', 'Service[ceilometer-alarm-notifier]', 'Service[ceilometer-agent-notification]'],
  value  => '604800',
}

ceilometer_config { 'database/mongodb_replica_set':
  before => 'Exec[ceilometer-dbsync]',
  name   => 'database/mongodb_replica_set',
  notify => ['Service[ceilometer-api]', 'Service[ceilometer-collector]', 'Service[ceilometer-agent-central]', 'Service[ceilometer-alarm-evaluator]', 'Service[ceilometer-alarm-notifier]', 'Service[ceilometer-agent-notification]'],
  value  => 'ceilometer',
}

ceilometer_config { 'database/time_to_live':
  before => 'Exec[ceilometer-dbsync]',
  name   => 'database/time_to_live',
  notify => ['Service[ceilometer-api]', 'Service[ceilometer-collector]', 'Service[ceilometer-agent-central]', 'Service[ceilometer-alarm-evaluator]', 'Service[ceilometer-alarm-notifier]', 'Service[ceilometer-agent-notification]'],
  value  => '-1',
}

ceilometer_config { 'keystone_authtoken/admin_password':
  before => 'Exec[ceilometer-dbsync]',
  name   => 'keystone_authtoken/admin_password',
  notify => ['Service[ceilometer-api]', 'Service[ceilometer-collector]', 'Service[ceilometer-agent-central]', 'Service[ceilometer-alarm-evaluator]', 'Service[ceilometer-alarm-notifier]', 'Service[ceilometer-agent-notification]'],
  secret => 'true',
  value  => 'WBfBSo6U',
}

ceilometer_config { 'keystone_authtoken/admin_tenant_name':
  before => 'Exec[ceilometer-dbsync]',
  name   => 'keystone_authtoken/admin_tenant_name',
  notify => ['Service[ceilometer-api]', 'Service[ceilometer-collector]', 'Service[ceilometer-agent-central]', 'Service[ceilometer-alarm-evaluator]', 'Service[ceilometer-alarm-notifier]', 'Service[ceilometer-agent-notification]'],
  value  => 'services',
}

ceilometer_config { 'keystone_authtoken/admin_user':
  before => 'Exec[ceilometer-dbsync]',
  name   => 'keystone_authtoken/admin_user',
  notify => ['Service[ceilometer-api]', 'Service[ceilometer-collector]', 'Service[ceilometer-agent-central]', 'Service[ceilometer-alarm-evaluator]', 'Service[ceilometer-alarm-notifier]', 'Service[ceilometer-agent-notification]'],
  value  => 'ceilometer',
}

ceilometer_config { 'keystone_authtoken/auth_admin_prefix':
  ensure => 'absent',
  before => 'Exec[ceilometer-dbsync]',
  name   => 'keystone_authtoken/auth_admin_prefix',
  notify => ['Service[ceilometer-api]', 'Service[ceilometer-collector]', 'Service[ceilometer-agent-central]', 'Service[ceilometer-alarm-evaluator]', 'Service[ceilometer-alarm-notifier]', 'Service[ceilometer-agent-notification]'],
}

ceilometer_config { 'keystone_authtoken/auth_host':
  before => 'Exec[ceilometer-dbsync]',
  name   => 'keystone_authtoken/auth_host',
  notify => ['Service[ceilometer-api]', 'Service[ceilometer-collector]', 'Service[ceilometer-agent-central]', 'Service[ceilometer-alarm-evaluator]', 'Service[ceilometer-alarm-notifier]', 'Service[ceilometer-agent-notification]'],
  value  => '192.168.0.7',
}

ceilometer_config { 'keystone_authtoken/auth_port':
  before => 'Exec[ceilometer-dbsync]',
  name   => 'keystone_authtoken/auth_port',
  notify => ['Service[ceilometer-api]', 'Service[ceilometer-collector]', 'Service[ceilometer-agent-central]', 'Service[ceilometer-alarm-evaluator]', 'Service[ceilometer-alarm-notifier]', 'Service[ceilometer-agent-notification]'],
  value  => '35357',
}

ceilometer_config { 'keystone_authtoken/auth_protocol':
  before => 'Exec[ceilometer-dbsync]',
  name   => 'keystone_authtoken/auth_protocol',
  notify => ['Service[ceilometer-api]', 'Service[ceilometer-collector]', 'Service[ceilometer-agent-central]', 'Service[ceilometer-alarm-evaluator]', 'Service[ceilometer-alarm-notifier]', 'Service[ceilometer-agent-notification]'],
  value  => 'http',
}

ceilometer_config { 'keystone_authtoken/auth_uri':
  before => 'Exec[ceilometer-dbsync]',
  name   => 'keystone_authtoken/auth_uri',
  notify => ['Service[ceilometer-api]', 'Service[ceilometer-collector]', 'Service[ceilometer-agent-central]', 'Service[ceilometer-alarm-evaluator]', 'Service[ceilometer-alarm-notifier]', 'Service[ceilometer-agent-notification]'],
  value  => 'http://192.168.0.7:5000/',
}

ceilometer_config { 'keystone_authtoken/identity_uri':
  ensure => 'absent',
  before => 'Exec[ceilometer-dbsync]',
  name   => 'keystone_authtoken/identity_uri',
  notify => ['Service[ceilometer-api]', 'Service[ceilometer-collector]', 'Service[ceilometer-agent-central]', 'Service[ceilometer-alarm-evaluator]', 'Service[ceilometer-alarm-notifier]', 'Service[ceilometer-agent-notification]'],
}

ceilometer_config { 'notification/ack_on_event_error':
  before => 'Exec[ceilometer-dbsync]',
  name   => 'notification/ack_on_event_error',
  notify => ['Service[ceilometer-api]', 'Service[ceilometer-collector]', 'Service[ceilometer-agent-central]', 'Service[ceilometer-alarm-evaluator]', 'Service[ceilometer-alarm-notifier]', 'Service[ceilometer-agent-notification]'],
  value  => 'true',
}

ceilometer_config { 'notification/store_events':
  before => 'Exec[ceilometer-dbsync]',
  name   => 'notification/store_events',
  notify => ['Service[ceilometer-api]', 'Service[ceilometer-collector]', 'Service[ceilometer-agent-central]', 'Service[ceilometer-alarm-evaluator]', 'Service[ceilometer-alarm-notifier]', 'Service[ceilometer-agent-notification]'],
  value  => 'true',
}

ceilometer_config { 'oslo_messaging_rabbit/heartbeat_rate':
  before => 'Exec[ceilometer-dbsync]',
  name   => 'oslo_messaging_rabbit/heartbeat_rate',
  notify => ['Service[ceilometer-api]', 'Service[ceilometer-collector]', 'Service[ceilometer-agent-central]', 'Service[ceilometer-alarm-evaluator]', 'Service[ceilometer-alarm-notifier]', 'Service[ceilometer-agent-notification]'],
  value  => '2',
}

ceilometer_config { 'oslo_messaging_rabbit/heartbeat_timeout_threshold':
  before => 'Exec[ceilometer-dbsync]',
  name   => 'oslo_messaging_rabbit/heartbeat_timeout_threshold',
  notify => ['Service[ceilometer-api]', 'Service[ceilometer-collector]', 'Service[ceilometer-agent-central]', 'Service[ceilometer-alarm-evaluator]', 'Service[ceilometer-alarm-notifier]', 'Service[ceilometer-agent-notification]'],
  value  => '0',
}

ceilometer_config { 'oslo_messaging_rabbit/kombu_ssl_ca_certs':
  ensure => 'absent',
  before => 'Exec[ceilometer-dbsync]',
  name   => 'oslo_messaging_rabbit/kombu_ssl_ca_certs',
  notify => ['Service[ceilometer-api]', 'Service[ceilometer-collector]', 'Service[ceilometer-agent-central]', 'Service[ceilometer-alarm-evaluator]', 'Service[ceilometer-alarm-notifier]', 'Service[ceilometer-agent-notification]'],
}

ceilometer_config { 'oslo_messaging_rabbit/kombu_ssl_certfile':
  ensure => 'absent',
  before => 'Exec[ceilometer-dbsync]',
  name   => 'oslo_messaging_rabbit/kombu_ssl_certfile',
  notify => ['Service[ceilometer-api]', 'Service[ceilometer-collector]', 'Service[ceilometer-agent-central]', 'Service[ceilometer-alarm-evaluator]', 'Service[ceilometer-alarm-notifier]', 'Service[ceilometer-agent-notification]'],
}

ceilometer_config { 'oslo_messaging_rabbit/kombu_ssl_keyfile':
  ensure => 'absent',
  before => 'Exec[ceilometer-dbsync]',
  name   => 'oslo_messaging_rabbit/kombu_ssl_keyfile',
  notify => ['Service[ceilometer-api]', 'Service[ceilometer-collector]', 'Service[ceilometer-agent-central]', 'Service[ceilometer-alarm-evaluator]', 'Service[ceilometer-alarm-notifier]', 'Service[ceilometer-agent-notification]'],
}

ceilometer_config { 'oslo_messaging_rabbit/kombu_ssl_version':
  ensure => 'absent',
  before => 'Exec[ceilometer-dbsync]',
  name   => 'oslo_messaging_rabbit/kombu_ssl_version',
  notify => ['Service[ceilometer-api]', 'Service[ceilometer-collector]', 'Service[ceilometer-agent-central]', 'Service[ceilometer-alarm-evaluator]', 'Service[ceilometer-alarm-notifier]', 'Service[ceilometer-agent-notification]'],
}

ceilometer_config { 'oslo_messaging_rabbit/rabbit_ha_queues':
  before => 'Exec[ceilometer-dbsync]',
  name   => 'oslo_messaging_rabbit/rabbit_ha_queues',
  notify => ['Service[ceilometer-api]', 'Service[ceilometer-collector]', 'Service[ceilometer-agent-central]', 'Service[ceilometer-alarm-evaluator]', 'Service[ceilometer-alarm-notifier]', 'Service[ceilometer-agent-notification]'],
  value  => 'false',
}

ceilometer_config { 'oslo_messaging_rabbit/rabbit_host':
  ensure => 'absent',
  before => 'Exec[ceilometer-dbsync]',
  name   => 'oslo_messaging_rabbit/rabbit_host',
  notify => ['Service[ceilometer-api]', 'Service[ceilometer-collector]', 'Service[ceilometer-agent-central]', 'Service[ceilometer-alarm-evaluator]', 'Service[ceilometer-alarm-notifier]', 'Service[ceilometer-agent-notification]'],
}

ceilometer_config { 'oslo_messaging_rabbit/rabbit_hosts':
  before => 'Exec[ceilometer-dbsync]',
  name   => 'oslo_messaging_rabbit/rabbit_hosts',
  notify => ['Service[ceilometer-api]', 'Service[ceilometer-collector]', 'Service[ceilometer-agent-central]', 'Service[ceilometer-alarm-evaluator]', 'Service[ceilometer-alarm-notifier]', 'Service[ceilometer-agent-notification]'],
  value  => '192.168.0.3:5673',
}

ceilometer_config { 'oslo_messaging_rabbit/rabbit_password':
  before => 'Exec[ceilometer-dbsync]',
  name   => 'oslo_messaging_rabbit/rabbit_password',
  notify => ['Service[ceilometer-api]', 'Service[ceilometer-collector]', 'Service[ceilometer-agent-central]', 'Service[ceilometer-alarm-evaluator]', 'Service[ceilometer-alarm-notifier]', 'Service[ceilometer-agent-notification]'],
  secret => 'true',
  value  => '1GXPbTgb',
}

ceilometer_config { 'oslo_messaging_rabbit/rabbit_port':
  ensure => 'absent',
  before => 'Exec[ceilometer-dbsync]',
  name   => 'oslo_messaging_rabbit/rabbit_port',
  notify => ['Service[ceilometer-api]', 'Service[ceilometer-collector]', 'Service[ceilometer-agent-central]', 'Service[ceilometer-alarm-evaluator]', 'Service[ceilometer-alarm-notifier]', 'Service[ceilometer-agent-notification]'],
}

ceilometer_config { 'oslo_messaging_rabbit/rabbit_use_ssl':
  before => 'Exec[ceilometer-dbsync]',
  name   => 'oslo_messaging_rabbit/rabbit_use_ssl',
  notify => ['Service[ceilometer-api]', 'Service[ceilometer-collector]', 'Service[ceilometer-agent-central]', 'Service[ceilometer-alarm-evaluator]', 'Service[ceilometer-alarm-notifier]', 'Service[ceilometer-agent-notification]'],
  value  => 'false',
}

ceilometer_config { 'oslo_messaging_rabbit/rabbit_userid':
  before => 'Exec[ceilometer-dbsync]',
  name   => 'oslo_messaging_rabbit/rabbit_userid',
  notify => ['Service[ceilometer-api]', 'Service[ceilometer-collector]', 'Service[ceilometer-agent-central]', 'Service[ceilometer-alarm-evaluator]', 'Service[ceilometer-alarm-notifier]', 'Service[ceilometer-agent-notification]'],
  value  => 'nova',
}

ceilometer_config { 'oslo_messaging_rabbit/rabbit_virtual_host':
  before => 'Exec[ceilometer-dbsync]',
  name   => 'oslo_messaging_rabbit/rabbit_virtual_host',
  notify => ['Service[ceilometer-api]', 'Service[ceilometer-collector]', 'Service[ceilometer-agent-central]', 'Service[ceilometer-alarm-evaluator]', 'Service[ceilometer-alarm-notifier]', 'Service[ceilometer-agent-notification]'],
  value  => '/',
}

ceilometer_config { 'publisher/metering_secret':
  before => 'Exec[ceilometer-dbsync]',
  name   => 'publisher/metering_secret',
  notify => ['Service[ceilometer-api]', 'Service[ceilometer-collector]', 'Service[ceilometer-agent-central]', 'Service[ceilometer-alarm-evaluator]', 'Service[ceilometer-alarm-notifier]', 'Service[ceilometer-agent-notification]'],
  secret => 'true',
  value  => 'tHq2rcoq',
}

ceilometer_config { 'service_credentials/os_auth_url':
  before => 'Exec[ceilometer-dbsync]',
  name   => 'service_credentials/os_auth_url',
  notify => ['Service[ceilometer-api]', 'Service[ceilometer-collector]', 'Service[ceilometer-agent-central]', 'Service[ceilometer-alarm-evaluator]', 'Service[ceilometer-alarm-notifier]', 'Service[ceilometer-agent-notification]'],
  value  => 'http://192.168.0.7:5000/v2.0',
}

ceilometer_config { 'service_credentials/os_cacert':
  ensure => 'absent',
  before => 'Exec[ceilometer-dbsync]',
  name   => 'service_credentials/os_cacert',
  notify => ['Service[ceilometer-api]', 'Service[ceilometer-collector]', 'Service[ceilometer-agent-central]', 'Service[ceilometer-alarm-evaluator]', 'Service[ceilometer-alarm-notifier]', 'Service[ceilometer-agent-notification]'],
}

ceilometer_config { 'service_credentials/os_endpoint_type':
  before => ['Service[ceilometer-agent-central]', 'Exec[ceilometer-dbsync]'],
  name   => 'service_credentials/os_endpoint_type',
  notify => ['Service[ceilometer-api]', 'Service[ceilometer-collector]', 'Service[ceilometer-agent-central]', 'Service[ceilometer-alarm-evaluator]', 'Service[ceilometer-alarm-notifier]', 'Service[ceilometer-agent-notification]'],
  value  => 'internalURL',
}

ceilometer_config { 'service_credentials/os_password':
  before => 'Exec[ceilometer-dbsync]',
  name   => 'service_credentials/os_password',
  notify => ['Service[ceilometer-api]', 'Service[ceilometer-collector]', 'Service[ceilometer-agent-central]', 'Service[ceilometer-alarm-evaluator]', 'Service[ceilometer-alarm-notifier]', 'Service[ceilometer-agent-notification]'],
  secret => 'true',
  value  => 'WBfBSo6U',
}

ceilometer_config { 'service_credentials/os_region_name':
  before => 'Exec[ceilometer-dbsync]',
  name   => 'service_credentials/os_region_name',
  notify => ['Service[ceilometer-api]', 'Service[ceilometer-collector]', 'Service[ceilometer-agent-central]', 'Service[ceilometer-alarm-evaluator]', 'Service[ceilometer-alarm-notifier]', 'Service[ceilometer-agent-notification]'],
  value  => 'RegionOne',
}

ceilometer_config { 'service_credentials/os_tenant_name':
  before => 'Exec[ceilometer-dbsync]',
  name   => 'service_credentials/os_tenant_name',
  notify => ['Service[ceilometer-api]', 'Service[ceilometer-collector]', 'Service[ceilometer-agent-central]', 'Service[ceilometer-alarm-evaluator]', 'Service[ceilometer-alarm-notifier]', 'Service[ceilometer-agent-notification]'],
  value  => 'services',
}

ceilometer_config { 'service_credentials/os_username':
  before => 'Exec[ceilometer-dbsync]',
  name   => 'service_credentials/os_username',
  notify => ['Service[ceilometer-api]', 'Service[ceilometer-collector]', 'Service[ceilometer-agent-central]', 'Service[ceilometer-alarm-evaluator]', 'Service[ceilometer-alarm-notifier]', 'Service[ceilometer-agent-notification]'],
  value  => 'ceilometer',
}

class { 'Ceilometer::Agent::Auth':
  auth_password    => 'WBfBSo6U',
  auth_region      => 'RegionOne',
  auth_tenant_name => 'services',
  auth_url         => 'http://192.168.0.7:5000/v2.0',
  auth_user        => 'ceilometer',
  name             => 'Ceilometer::Agent::Auth',
}

class { 'Ceilometer::Agent::Central':
  enabled        => 'true',
  manage_service => 'true',
  name           => 'Ceilometer::Agent::Central',
  package_ensure => 'present',
}

class { 'Ceilometer::Agent::Notification':
  ack_on_event_error => 'true',
  enabled            => 'true',
  manage_service     => 'true',
  name               => 'Ceilometer::Agent::Notification',
  package_ensure     => 'present',
  store_events       => 'true',
}

class { 'Ceilometer::Alarm::Evaluator':
  enabled             => 'true',
  evaluation_interval => '60',
  evaluation_service  => 'ceilometer.alarm.service.SingletonAlarmService',
  manage_service      => 'true',
  name                => 'Ceilometer::Alarm::Evaluator',
  partition_rpc_topic => 'alarm_partition_coordination',
  record_history      => 'true',
}

class { 'Ceilometer::Alarm::Notifier':
  enabled                  => 'true',
  manage_service           => 'true',
  name                     => 'Ceilometer::Alarm::Notifier',
  rest_notifier_ssl_verify => 'true',
}

class { 'Ceilometer::Api':
  enabled                    => 'true',
  host                       => '192.168.0.3',
  keystone_auth_admin_prefix => 'false',
  keystone_auth_uri          => 'false',
  keystone_host              => '192.168.0.7',
  keystone_identity_uri      => 'false',
  keystone_password          => 'WBfBSo6U',
  keystone_port              => '35357',
  keystone_protocol          => 'http',
  keystone_tenant            => 'services',
  keystone_user              => 'ceilometer',
  manage_service             => 'true',
  name                       => 'Ceilometer::Api',
  package_ensure             => 'present',
  port                       => '8777',
  service_name               => 'ceilometer-api',
}

class { 'Ceilometer::Client':
  ensure => 'present',
  name   => 'Ceilometer::Client',
}

class { 'Ceilometer::Collector':
  enabled        => 'true',
  manage_service => 'true',
  name           => 'Ceilometer::Collector',
  package_ensure => 'present',
  udp_address    => '0.0.0.0',
  udp_port       => '4952',
}

class { 'Ceilometer::Db::Sync':
  name => 'Ceilometer::Db::Sync',
}

class { 'Ceilometer::Db':
  database_connection => 'mongodb://ceilometer:Toe5phw4@192.168.0.1/ceilometer',
  name                => 'Ceilometer::Db',
  sync_db             => 'true',
}

class { 'Ceilometer::Expirer':
  enable_cron  => 'True',
  hour         => '0',
  minute       => '0',
  month        => '*',
  monthday     => '*',
  name         => 'Ceilometer::Expirer',
  time_to_live => '-1',
  weekday      => '0',
}

class { 'Ceilometer::Params':
  name => 'Ceilometer::Params',
}

class { 'Ceilometer::Policy':
  name        => 'Ceilometer::Policy',
  notify      => 'Service[ceilometer-api]',
  policies    => {},
  policy_path => '/etc/ceilometer/policy.json',
}

class { 'Ceilometer':
  alarm_history_time_to_live         => '-1',
  debug                              => 'false',
  event_time_to_live                 => '604800',
  http_timeout                       => '600',
  kombu_ssl_version                  => 'TLSv1',
  log_dir                            => '/var/log/ceilometer',
  log_facility                       => 'LOG_LOCAL0',
  metering_secret                    => 'tHq2rcoq',
  metering_time_to_live              => '604800',
  name                               => 'Ceilometer',
  notification_topics                => 'notifications',
  package_ensure                     => 'present',
  qpid_heartbeat                     => '60',
  qpid_hostname                      => 'localhost',
  qpid_password                      => 'guest',
  qpid_port                          => '5672',
  qpid_protocol                      => 'tcp',
  qpid_reconnect                     => 'true',
  qpid_reconnect_interval            => '0',
  qpid_reconnect_interval_max        => '0',
  qpid_reconnect_interval_min        => '0',
  qpid_reconnect_limit               => '0',
  qpid_reconnect_timeout             => '0',
  qpid_tcp_nodelay                   => 'true',
  qpid_username                      => 'guest',
  rabbit_heartbeat_rate              => '2',
  rabbit_heartbeat_timeout_threshold => '0',
  rabbit_host                        => '127.0.0.1',
  rabbit_hosts                       => '192.168.0.3:5673',
  rabbit_password                    => '1GXPbTgb',
  rabbit_port                        => '5672',
  rabbit_use_ssl                     => 'false',
  rabbit_userid                      => 'nova',
  rabbit_virtual_host                => '/',
  rpc_backend                        => 'rabbit',
  use_stderr                         => 'false',
  use_syslog                         => 'true',
  verbose                            => 'true',
}

class { 'Ceilometer_ha::Agent::Central':
  name => 'Ceilometer_ha::Agent::Central',
}

class { 'Ceilometer_ha::Alarm::Evaluator':
  name => 'Ceilometer_ha::Alarm::Evaluator',
}

class { 'Openstack::Ceilometer':
  amqp_hosts            => '192.168.0.3:5673',
  amqp_password         => '1GXPbTgb',
  amqp_user             => 'nova',
  db_dbname             => 'ceilometer',
  db_host               => '192.168.0.1',
  db_password           => 'Toe5phw4',
  db_type               => 'mongodb',
  db_user               => 'ceilometer',
  debug                 => 'false',
  event_time_to_live    => '604800',
  ext_mongo             => 'false',
  ha_mode               => 'true',
  host                  => '192.168.0.3',
  http_timeout          => '600',
  keystone_host         => '192.168.0.7',
  keystone_password     => 'WBfBSo6U',
  keystone_region       => 'RegionOne',
  keystone_tenant       => 'services',
  keystone_user         => 'ceilometer',
  metering_secret       => 'tHq2rcoq',
  metering_time_to_live => '604800',
  mongo_replicaset      => 'ceilometer',
  name                  => 'Openstack::Ceilometer',
  on_compute            => 'false',
  on_controller         => 'true',
  os_endpoint_type      => 'internalURL',
  port                  => '8777',
  rabbit_ha_queues      => 'true',
  swift_rados_backend   => 'true',
  syslog_log_facility   => 'LOG_LOCAL0',
  use_stderr            => 'false',
  use_syslog            => 'true',
  verbose               => 'true',
}

class { 'Settings':
  name => 'Settings',
}

class { 'main':
  name => 'main',
}

cron { 'ceilometer-expirer':
  command     => 'ceilometer-expirer',
  environment => 'PATH=/bin:/usr/bin:/usr/sbin SHELL=/bin/sh',
  hour        => '0',
  minute      => '0',
  month       => '*',
  monthday    => '*',
  name        => 'ceilometer-expirer',
  user        => 'ceilometer',
  weekday     => '0',
}

cs_resource { 'p_ceilometer-agent-central':
  ensure          => 'present',
  before          => 'Service[ceilometer-agent-central]',
  metadata        => {'resource-stickiness' => '1'},
  name            => 'p_ceilometer-agent-central',
  operations      => {'monitor' => {'interval' => '20', 'timeout' => '30'}, 'start' => {'timeout' => '360'}, 'stop' => {'timeout' => '360'}},
  parameters      => {'user' => 'ceilometer'},
  primitive_class => 'ocf',
  primitive_type  => 'ceilometer-agent-central',
  provided_by     => 'fuel',
}

cs_resource { 'p_ceilometer-alarm-evaluator':
  ensure          => 'present',
  before          => 'Service[ceilometer-alarm-evaluator]',
  metadata        => {'resource-stickiness' => '1'},
  name            => 'p_ceilometer-alarm-evaluator',
  operations      => {'monitor' => {'interval' => '20', 'timeout' => '30'}, 'start' => {'timeout' => '360'}, 'stop' => {'timeout' => '360'}},
  parameters      => {'user' => 'ceilometer'},
  primitive_class => 'ocf',
  primitive_type  => 'ceilometer-alarm-evaluator',
  provided_by     => 'fuel',
}

exec { 'ceilometer-dbsync':
  command     => 'ceilometer-dbsync --config-file=/etc/ceilometer/ceilometer.conf',
  logoutput   => 'on_failure',
  notify      => ['Service[ceilometer-api]', 'Service[ceilometer-agent-central]'],
  path        => '/usr/bin',
  refreshonly => 'true',
  user        => 'ceilometer',
}

file { 'ocf_handler_ceilometer-agent-central':
  ensure  => 'present',
  before  => 'Service[ceilometer-agent-central]',
  content => '#!/bin/bash
export PATH='/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin'
export OCF_ROOT='/usr/lib/ocf'
export OCF_RA_VERSION_MAJOR='1'
export OCF_RA_VERSION_MINOR='0'
export OCF_RESOURCE_INSTANCE='p_ceilometer-agent-central'

# OCF Parameters
                                    export OCF_RESKEY_user='ceilometer'
    
help() {
cat<<EOF
OCF wrapper for ceilometer-agent-central Pacemaker primitive

Usage: ocf_handler_ceilometer-agent-central [-dh] (action)

Options:
-d - Use set -x to debug the shell script
-h - Show this help

Main actions:
* start
* stop
* monitor
* meta-data
* validate-all

Multistate:
* promote
* demote
* notify

Migration:
* migrate_to
* migrate_from

Optional and unused:
* usage
* help
* status
* reload
* restart
* recover
EOF
}

red() {
  echo -e "\033[31m${1}\033[0m"
}

green() {
  echo -e "\033[32m${1}\033[0m"
}

blue() {
  echo -e "\033[34m${1}\033[0m"
}

ec2error() {
  case "${1}" in
    0) green 'Success' ;;
    1) red 'Error: Generic' ;;
    2) red 'Error: Arguments' ;;
    3) red 'Error: Unimplemented' ;;
    4) red 'Error: Permissions' ;;
    5) red 'Error: Installation' ;;
    6) red 'Error: Configuration' ;;
    7) blue 'Not Running' ;;
    8) green 'Master Running' ;;
    9) red 'Master Failed' ;;
    *) red "Unknown" ;;
  esac
}

DEBUG='0'
while getopts ':dh' opt; do
  case $opt in
    d)
      DEBUG='1'
      ;;
    h)
      help
      exit 0
      ;;
    \?)
      echo "Invalid option: -${OPTARG}" >&2
      help
      exit 1
      ;;
  esac
done

shift "$((OPTIND - 1))"

ACTION="${1}"

# set default action to monitor
if [ "${ACTION}" = '' ]; then
  ACTION='monitor'
fi

# alias status to monitor
if [ "${ACTION}" = 'status' ]; then
  ACTION='monitor'
fi

# view defined OCF parameters
if [ "${ACTION}" = 'params' ]; then
  env | grep 'OCF_'
  exit 0
fi

if [ "${DEBUG}" = '1' ]; then
  bash -x /usr/lib/ocf/resource.d/fuel/ceilometer-agent-central "${ACTION}"
else
  /usr/lib/ocf/resource.d/fuel/ceilometer-agent-central "${ACTION}"
fi
ec="${?}"

message="$(ec2error ${ec})"
echo "Exit status: ${message} (${ec})"
exit "${ec}"
',
  group   => 'root',
  mode    => '0700',
  owner   => 'root',
  path    => '/usr/local/bin/ocf_handler_ceilometer-agent-central',
}

file { 'ocf_handler_ceilometer-alarm-evaluator':
  ensure  => 'present',
  before  => 'Service[ceilometer-alarm-evaluator]',
  content => '#!/bin/bash
export PATH='/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin'
export OCF_ROOT='/usr/lib/ocf'
export OCF_RA_VERSION_MAJOR='1'
export OCF_RA_VERSION_MINOR='0'
export OCF_RESOURCE_INSTANCE='p_ceilometer-alarm-evaluator'

# OCF Parameters
                                    export OCF_RESKEY_user='ceilometer'
    
help() {
cat<<EOF
OCF wrapper for ceilometer-alarm-evaluator Pacemaker primitive

Usage: ocf_handler_ceilometer-alarm-evaluator [-dh] (action)

Options:
-d - Use set -x to debug the shell script
-h - Show this help

Main actions:
* start
* stop
* monitor
* meta-data
* validate-all

Multistate:
* promote
* demote
* notify

Migration:
* migrate_to
* migrate_from

Optional and unused:
* usage
* help
* status
* reload
* restart
* recover
EOF
}

red() {
  echo -e "\033[31m${1}\033[0m"
}

green() {
  echo -e "\033[32m${1}\033[0m"
}

blue() {
  echo -e "\033[34m${1}\033[0m"
}

ec2error() {
  case "${1}" in
    0) green 'Success' ;;
    1) red 'Error: Generic' ;;
    2) red 'Error: Arguments' ;;
    3) red 'Error: Unimplemented' ;;
    4) red 'Error: Permissions' ;;
    5) red 'Error: Installation' ;;
    6) red 'Error: Configuration' ;;
    7) blue 'Not Running' ;;
    8) green 'Master Running' ;;
    9) red 'Master Failed' ;;
    *) red "Unknown" ;;
  esac
}

DEBUG='0'
while getopts ':dh' opt; do
  case $opt in
    d)
      DEBUG='1'
      ;;
    h)
      help
      exit 0
      ;;
    \?)
      echo "Invalid option: -${OPTARG}" >&2
      help
      exit 1
      ;;
  esac
done

shift "$((OPTIND - 1))"

ACTION="${1}"

# set default action to monitor
if [ "${ACTION}" = '' ]; then
  ACTION='monitor'
fi

# alias status to monitor
if [ "${ACTION}" = 'status' ]; then
  ACTION='monitor'
fi

# view defined OCF parameters
if [ "${ACTION}" = 'params' ]; then
  env | grep 'OCF_'
  exit 0
fi

if [ "${DEBUG}" = '1' ]; then
  bash -x /usr/lib/ocf/resource.d/fuel/ceilometer-alarm-evaluator "${ACTION}"
else
  /usr/lib/ocf/resource.d/fuel/ceilometer-alarm-evaluator "${ACTION}"
fi
ec="${?}"

message="$(ec2error ${ec})"
echo "Exit status: ${message} (${ec})"
exit "${ec}"
',
  group   => 'root',
  mode    => '0700',
  owner   => 'root',
  path    => '/usr/local/bin/ocf_handler_ceilometer-alarm-evaluator',
}

group { 'ceilometer':
  name    => 'ceilometer',
  require => 'Package[ceilometer-common]',
}

pacemaker_wrappers::service { 'ceilometer-agent-central':
  ensure             => 'present',
  create_primitive   => 'true',
  handler_root_path  => '/usr/local/bin',
  metadata           => {'resource-stickiness' => '1'},
  name               => 'ceilometer-agent-central',
  ocf_root_path      => '/usr/lib/ocf',
  operations         => {'monitor' => {'interval' => '20', 'timeout' => '30'}, 'start' => {'timeout' => '360'}, 'stop' => {'timeout' => '360'}},
  parameters         => {'user' => 'ceilometer'},
  prefix             => 'true',
  primitive_class    => 'ocf',
  primitive_provider => 'fuel',
  primitive_type     => 'ceilometer-agent-central',
  use_handler        => 'true',
}

pacemaker_wrappers::service { 'ceilometer-alarm-evaluator':
  ensure             => 'present',
  create_primitive   => 'true',
  handler_root_path  => '/usr/local/bin',
  metadata           => {'resource-stickiness' => '1'},
  name               => 'ceilometer-alarm-evaluator',
  ocf_root_path      => '/usr/lib/ocf',
  operations         => {'monitor' => {'interval' => '20', 'timeout' => '30'}, 'start' => {'timeout' => '360'}, 'stop' => {'timeout' => '360'}},
  parameters         => {'user' => 'ceilometer'},
  prefix             => 'true',
  primitive_class    => 'ocf',
  primitive_provider => 'fuel',
  primitive_type     => 'ceilometer-alarm-evaluator',
  use_handler        => 'true',
}

package { 'ceilometer-agent-central':
  ensure => 'present',
  before => ['Service[ceilometer-agent-central]', 'Class[Ceilometer_ha::Agent::Central]'],
  name   => 'ceilometer-agent-central',
  notify => 'Exec[ceilometer-dbsync]',
  tag    => ['openstack', 'ceilometer-package'],
}

package { 'ceilometer-agent-notification':
  ensure => 'present',
  before => 'Service[ceilometer-agent-notification]',
  name   => 'ceilometer-agent-notification',
  tag    => 'openstack',
}

package { 'ceilometer-alarm-evaluator':
  ensure => 'present',
  before => ['Service[ceilometer-alarm-evaluator]', 'Service[ceilometer-alarm-notifier]', 'Class[Ceilometer_ha::Alarm::Evaluator]'],
  name   => 'ceilometer-alarm-evaluator',
  tag    => 'openstack',
}

package { 'ceilometer-alarm-notifier':
  ensure => 'present',
  before => ['Service[ceilometer-alarm-evaluator]', 'Service[ceilometer-alarm-notifier]'],
  name   => 'ceilometer-alarm-notifier',
  tag    => 'openstack',
}

package { 'ceilometer-api':
  ensure => 'present',
  before => ['Service[ceilometer-api]', 'Class[Ceilometer::Policy]'],
  name   => 'ceilometer-api',
  notify => 'Exec[ceilometer-dbsync]',
  tag    => ['openstack', 'ceilometer-package'],
}

package { 'ceilometer-backend-package':
  ensure => 'present',
  name   => 'python-pymongo',
  tag    => 'openstack',
}

package { 'ceilometer-collector':
  ensure => 'present',
  before => 'Service[ceilometer-collector]',
  name   => 'ceilometer-collector',
}

package { 'ceilometer-common':
  ensure => 'present',
  before => ['Class[Ceilometer::Db]', 'Service[ceilometer-api]', 'Class[Ceilometer::Expirer]', 'Service[ceilometer-collector]', 'Service[ceilometer-agent-central]', 'Service[ceilometer-alarm-evaluator]', 'Service[ceilometer-alarm-notifier]', 'Service[ceilometer-agent-notification]', 'Class[Ceilometer_ha::Agent::Central]', 'Class[Ceilometer_ha::Alarm::Evaluator]'],
  name   => 'ceilometer-common',
  notify => ['Exec[ceilometer-dbsync]', 'Service[ceilometer-alarm-evaluator]'],
  tag    => ['openstack', 'ceilometer-package'],
}

package { 'python-ceilometerclient':
  ensure => 'present',
  name   => 'python-ceilometerclient',
  tag    => 'openstack',
}

service { 'ceilometer-agent-central':
  ensure     => 'running',
  enable     => 'true',
  hasrestart => 'true',
  hasstatus  => 'true',
  name       => 'ceilometer-agent-central',
  provider   => 'pacemaker',
  tag        => 'ceilometer-service',
}

service { 'ceilometer-agent-notification':
  ensure     => 'running',
  enable     => 'true',
  hasrestart => 'true',
  hasstatus  => 'true',
  name       => 'ceilometer-agent-notification',
}

service { 'ceilometer-alarm-evaluator':
  ensure     => 'running',
  enable     => 'true',
  hasrestart => 'true',
  hasstatus  => 'true',
  name       => 'ceilometer-alarm-evaluator',
  provider   => 'pacemaker',
}

service { 'ceilometer-alarm-notifier':
  ensure     => 'running',
  enable     => 'true',
  hasrestart => 'true',
  hasstatus  => 'true',
  name       => 'ceilometer-alarm-notifier',
}

service { 'ceilometer-api':
  ensure     => 'running',
  enable     => 'true',
  hasrestart => 'true',
  hasstatus  => 'true',
  name       => 'ceilometer-api',
  require    => 'Class[Ceilometer::Db]',
  tag        => 'ceilometer-service',
}

service { 'ceilometer-collector':
  ensure     => 'running',
  enable     => 'true',
  hasrestart => 'true',
  hasstatus  => 'true',
  name       => 'ceilometer-collector',
}

stage { 'main':
  name => 'main',
}

user { 'ceilometer':
  gid     => 'ceilometer',
  name    => 'ceilometer',
  require => 'Package[ceilometer-common]',
  system  => 'true',
}

