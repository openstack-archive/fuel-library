class { 'Settings':
  name => 'Settings',
}

class { 'main':
  name => 'main',
}

file { '/etc/hiera/globals.yaml':
  ensure  => 'present',
  content => '
--- 
  access_hash: 
    email: "admin@localhost"
    metadata: 
      label: Access
      weight: 10
    password: admin
    tenant: admin
    user: admin
  amqp_hosts: "192.168.0.4:5673"
  amqp_port: "5673"
  apache_ports: 
    - "80"
    - "8888"
    - "5000"
    - "35357"
  base_mac: 
  base_syslog_hash: 
    syslog_port: "514"
    syslog_server: "10.108.0.2"
  ceph_monitor_nodes: 
    node-137: &id001
      
      swift_zone: "1"
      uid: "137"
      fqdn: node-137.test.domain.local
      network_roles: 
        keystone/api: "192.168.0.4"
        neutron/api: "192.168.0.4"
        mgmt/database: "192.168.0.4"
        sahara/api: "192.168.0.4"
        heat/api: "192.168.0.4"
        ceilometer/api: "192.168.0.4"
        ex: "172.16.0.5"
        ceph/public: "192.168.0.4"
        ceph/radosgw: "172.16.0.5"
        management: "192.168.0.4"
        swift/api: "192.168.0.4"
        mgmt/api: "192.168.0.4"
        storage: "192.168.1.4"
        mgmt/corosync: "192.168.0.4"
        cinder/api: "192.168.0.4"
        public/vip: "172.16.0.5"
        swift/replication: "192.168.1.4"
        mgmt/messaging: "192.168.0.4"
        neutron/mesh: "192.168.0.4"
        admin/pxe: "10.109.0.9"
        mongo/db: "192.168.0.4"
        neutron/private: 
        neutron/floating: 
        fw-admin: "10.109.0.9"
        glance/api: "192.168.0.4"
        mgmt/vip: "192.168.0.4"
        murano/api: "192.168.0.4"
        nova/api: "192.168.0.4"
        horizon: "192.168.0.4"
        mgmt/memcache: "192.168.0.4"
        cinder/iscsi: "192.168.1.4"
        ceph/replication: "192.168.1.4"
      user_node_name: "Untitled (6a:e7)"
      node_roles: 
        - primary-controller
      name: node-137
  ceph_primary_monitor_node: 
    node-137: *id001
  ceph_rgw_nodes: 
    node-137: *id001
  ceilometer_hash: 
    db_password: ZCWaANKg
    enabled: false
    metering_secret: "5gCCPfO8"
    user_password: Ag2mna7b
    event_time_to_live: "604800"
    metering_time_to_live: "604800"
    http_timeout: "600"
  ceilometer_nodes: 
    node-137: *id001
  cinder_hash: 
    db_password: VwpNB13X
    fixed_key: "0d983a86451032ba0b738fc12a654e314354aa0194390eed54608196831a425e"
    user_password: o9msdnTx
  cinder_nodes: 
    node-137: *id001
  cinder_rate_limits: 
    POST: "100000"
    POST_SERVERS: "100000"
    PUT: "100000"
    GET: "100000"
    DELETE: "100000"
  corosync_roles: 
    - primary-controller
    - controller
  custom_mysql_setup_class: galera
  database_nodes: 
    node-137: *id001
  debug: false
  default_gateway: 
    - "172.16.0.1"
  deployment_mode: ha_compact
  dns_nameservers: 
    - "8.8.4.4"
    - "8.8.8.8"
  glance_backend: file
  glance_hash: 
    db_password: s5aslXZn
    image_cache_max_size: "5368709120"
    user_password: UEtUqI9Z
  glance_known_stores: false
  heat_hash: 
    auth_encryption_key: "194abdbbc31aded70db9b2084be8e215"
    db_password: SvgZ3tKP
    enabled: true
    rabbit_password: "0fPV94mX"
    user_password: Nlq9bTGV
  heat_roles: 
    - primary-controller
    - controller
  horizon_nodes: 
    node-137: *id001
  node_name: node-136
  idle_timeout: "3600"
  keystone_hash: 
    service_token_off: false
    admin_token: Uo10oynr
    db_password: MnrQiwLn
  manage_volumes: false
  management_network_range: "192.168.0.0/24"
  master_ip: "10.108.0.2"
  max_overflow: 20
  max_pool_size: 20
  max_retries: "-1"
  mirror_type: external
  mountpoints: 
    - "1"
    - "2"
  mongo_roles: 
    - primary-mongo
    - mongo
  multi_host: true
  murano_hash: 
    db_password: "07KOdk75"
    enabled: false
    rabbit_password: rJfH9CSy
    user_password: mrQ9d0JW
  murano_roles: 
    - primary-controller
    - controller
  mysql_hash: 
    root_password: M3VTf8U9
    wsrep_password: jMCDynJR
  network_config: 
  network_manager: nova.network.manager.FlatDHCPManager
  network_scheme: 
    endpoints: 
      br-ex: 
        IP: 
          - "172.16.0.4/24"
        gateway: "172.16.0.1"
      br-fw-admin: 
        IP: 
          - "10.108.0.7/24"
      br-mgmt: 
        IP: 
          - "192.168.0.3/24"
      br-storage: 
        IP: 
          - "192.168.1.3/24"
      eth0.103: 
        IP: none
    interfaces: 
      eth0: {}
      eth1: {}
      eth2: {}
      eth3: {}
      eth4: {}
    provider: lnx
    roles: 
      novanetwork/fixed: eth0.103
      ex: br-ex
      public/vip: br-ex
      neutron/floating: br-floating
      storage: br-storage
      keystone/api: br-mgmt
      neutron/api: br-mgmt
      mgmt/database: br-mgmt
      sahara/api: br-mgmt
      ceilometer/api: br-mgmt
      mgmt/vip: br-mgmt
      ceph/public: br-mgmt
      mgmt/messaging: br-mgmt
      management: br-mgmt
      swift/api: br-mgmt
      mgmt/api: br-mgmt
      mgmt/corosync: br-mgmt
      cinder/api: br-mgmt
      swift/replication: br-storage
      neutron/mesh: br-mgmt
      admin/pxe: br-fw-admin
      mongo/db: br-mgmt
      neutron/private: br-prv
      fw-admin: br-fw-admin
      glance/api: br-mgmt
      heat/api: br-mgmt
      murano/api: br-mgmt
      nova/api: br-mgmt
      horizon: br-mgmt
      mgmt/memcache: br-mgmt
      cinder/iscsi: br-storage
      ceph/replication: br-storage
    transformations: 
      - action: add-br
        name: br-fw-admin
      - action: add-br
        name: br-storage
      - action: add-br
        name: br-mgmt
      - action: add-br
        name: br-ex
      - action: add-port
        bridge: br-fw-admin
        name: eth0
      - action: add-port
        bridge: br-storage
        name: eth0.102
      - action: add-port
        bridge: br-mgmt
        name: eth0.101
      - action: add-port
        bridge: br-ex
        name: eth1
      - action: add-port
        name: eth0.103
    version: "1.1"
  network_size: 65536
  neutron_config: {}
  neutron_db_password: 
  neutron_metadata_proxy_secret: 
  neutron_nodes: 
    node-137: *id001
  neutron_user_password: 
  node: 
    swift_zone: "1"
    uid: "136"
    fqdn: node-136.test.domain.local
    network_roles: 
      keystone/api: "192.168.0.3"
      neutron/api: "192.168.0.3"
      mgmt/database: "192.168.0.3"
      sahara/api: "192.168.0.3"
      heat/api: "192.168.0.3"
      ceilometer/api: "192.168.0.3"
      ex: "172.16.0.4"
      ceph/public: "192.168.0.3"
      ceph/radosgw: "172.16.0.4"
      management: "192.168.0.3"
      swift/api: "192.168.0.3"
      mgmt/api: "192.168.0.3"
      storage: "192.168.1.3"
      mgmt/corosync: "192.168.0.3"
      cinder/api: "192.168.0.3"
      public/vip: "172.16.0.4"
      swift/replication: "192.168.1.3"
      mgmt/messaging: "192.168.0.3"
      neutron/mesh: "192.168.0.3"
      admin/pxe: "10.109.0.9"
      mongo/db: "192.168.0.3"
      neutron/private: 
      neutron/floating: 
      fw-admin: "10.109.0.9"
      glance/api: "192.168.0.3"
      mgmt/vip: "192.168.0.3"
      murano/api: "192.168.0.3"
      nova/api: "192.168.0.3"
      horizon: "192.168.0.3"
      mgmt/memcache: "192.168.0.3"
      cinder/iscsi: "192.168.1.3"
      ceph/replication: "192.168.1.3"
    user_node_name: "Untitled (6a:e7)"
    node_roles: &id002
      
      - compute
    name: node-136
  nodes_hash: 
    - fqdn: node-135.test.domain.local
      internal_address: "192.168.0.2"
      internal_netmask: "255.255.255.0"
      name: node-135
      public_address: "172.16.0.3"
      public_netmask: "255.255.255.0"
      role: cinder
      storage_address: "192.168.1.2"
      storage_netmask: "255.255.255.0"
      swift_zone: "135"
      uid: "135"
      user_node_name: "Untitled (18:c9)"
    - fqdn: node-136.test.domain.local
      internal_address: "192.168.0.3"
      internal_netmask: "255.255.255.0"
      name: node-136
      public_address: "172.16.0.4"
      public_netmask: "255.255.255.0"
      role: compute
      storage_address: "192.168.1.3"
      storage_netmask: "255.255.255.0"
      swift_zone: "136"
      uid: "136"
      user_node_name: "Untitled (1d:4b)"
    - fqdn: node-137.test.domain.local
      internal_address: "192.168.0.4"
      internal_netmask: "255.255.255.0"
      name: node-137
      public_address: "172.16.0.5"
      public_netmask: "255.255.255.0"
      role: primary-controller
      storage_address: "192.168.1.4"
      storage_netmask: "255.255.255.0"
      swift_zone: "137"
      uid: "137"
      user_node_name: "Untitled (34:45)"
  nova_db_password: aAU4jYDt
  nova_hash: 
    db_password: aAU4jYDt
    state_path: /var/lib/nova
    user_password: UyrT2Ama
    vncproxy_protocol: https
  nova_rate_limits: 
    POST: "100000"
    POST_SERVERS: "100000"
    PUT: "1000"
    GET: "100000"
    DELETE: "100000"
  nova_report_interval: "60"
  nova_service_down_time: "180"
  novanetwork_params: 
    network_manager: FlatDHCPManager
    network_size: 65536
    num_networks: 1
  num_networks: 1
  openstack_version: "2014.2-6.1"
  primary_controller: false
  private_int: eth0.103
  queue_provider: rabbitmq
  rabbit_ha_queues: true
  rabbit_hash: 
    password: zrMvquYX
    user: nova
  node_role: compute
  roles: *id002
  sahara_hash: 
    db_password: xzyWeMAy
    enabled: false
    user_password: EqqXoxx9
  sahara_roles: 
    - primary-controller
    - controller
  sql_connection: "mysql://nova:aAU4jYDt@192.168.0.5/nova?read_timeout = 6 0"
  storage_hash: 
    ephemeral_ceph: false
    images_ceph: false
    images_vcenter: false
    iser: false
    metadata: 
      label: Storage
      weight: 60
    objects_ceph: false
    osd_pool_size: "2"
    pg_num: 128
    volumes_ceph: false
    volumes_lvm: true
  swift_hash: 
    user_password: UcPlc9Wp
  syslog_hash: 
    metadata: 
      label: Syslog
      weight: 50
    syslog_port: "514"
    syslog_server: ""
    syslog_transport: tcp
  syslog_log_facility_ceilometer: LOG_LOCAL0
  syslog_log_facility_ceph: LOG_LOCAL0
  syslog_log_facility_cinder: LOG_LOCAL3
  syslog_log_facility_glance: LOG_LOCAL2
  syslog_log_facility_heat: LOG_LOCAL0
  syslog_log_facility_keystone: LOG_LOCAL7
  syslog_log_facility_murano: LOG_LOCAL0
  syslog_log_facility_neutron: LOG_LOCAL4
  syslog_log_facility_nova: LOG_LOCAL6
  syslog_log_facility_sahara: LOG_LOCAL0
  use_ceilometer: false
  use_monit: false
  use_neutron: false
  use_syslog: true
  vcenter_hash: {}
  verbose: true
  vlan_start: 
  management_vip: "192.168.0.5"
  database_vip: "192.168.0.5"
  service_endpoint: "192.168.0.5"
  public_vip: "172.16.0.6"
  management_vrouter_vip: "192.168.0.6"
  public_vrouter_vip: "172.16.0.7"
  memcache_roles: 
    - primary-controller
    - controller
  swift_master_role: primary-controller
  swift_nodes: 
    node-137: *id001
  swift_proxies: 
    node-137: *id001
  swift_proxy_caches: 
    node-137: *id001
  is_primary_swift_proxy: false
  nova_api_nodes: 
    node-137: *id001
',
  group   => 'root',
  mode    => '0644',
  owner   => 'root',
  path    => '/etc/hiera/globals.yaml',
}

stage { 'main':
  name => 'main',
}

