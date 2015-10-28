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
    user: ceilometerHA
    password: ceilometerHA
    email: "admin@localhost"
    tenant: ceilometerHA
    metadata: 
      weight: 10
      label: Access
  amqp_hosts: "10.108.2.4:5673, 10.108.2.6:5673, 10.108.2.5:5673"
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
    node-1: &id001
      
      swift_zone: "1"
      uid: "1"
      fqdn: node-1.test.domain.local
      network_roles: 
        keystone/api: "10.108.2.4"
        neutron/api: "10.108.2.4"
        mgmt/database: "10.108.2.4"
        sahara/api: "10.108.2.4"
        heat/api: "10.108.2.4"
        ceilometer/api: "10.108.2.4"
        ex: "10.108.1.4"
        ceph/public: "10.108.2.4"
        ceph/radosgw: "10.108.1.4"
        management: "10.108.2.4"
        swift/api: "10.108.2.4"
        mgmt/api: "10.108.2.4"
        storage: "10.108.4.2"
        mgmt/corosync: "10.108.2.4"
        cinder/api: "10.108.2.4"
        public/vip: "10.108.1.4"
        swift/replication: "10.108.4.2"
        mgmt/messaging: "10.108.2.4"
        neutron/mesh: "10.108.2.4"
        admin/pxe: "10.109.0.9"
        mongo/db: "10.108.2.4"
        neutron/private: 
        neutron/floating: 
        fw-admin: "10.109.0.9"
        glance/api: "10.108.2.4"
        mgmt/vip: "10.108.2.4"
        murano/api: "10.108.2.4"
        nova/api: "10.108.2.4"
        horizon: "10.108.2.4"
        mgmt/memcache: "10.108.2.4"
        cinder/iscsi: "10.108.4.2"
        ceph/replication: "10.108.4.2"
      user_node_name: "Untitled (6a:e7)"
      node_roles: &id004
        
        - primary-controller
      name: node-1
    node-2: &id002
      
      swift_zone: "1"
      uid: "2"
      fqdn: node-2.test.domain.local
      network_roles: 
        keystone/api: "10.108.2.5"
        neutron/api: "10.108.2.5"
        mgmt/database: "10.108.2.5"
        sahara/api: "10.108.2.5"
        heat/api: "10.108.2.5"
        ceilometer/api: "10.108.2.5"
        ex: "10.108.1.5"
        ceph/public: "10.108.2.5"
        ceph/radosgw: "10.108.1.5"
        management: "10.108.2.5"
        swift/api: "10.108.2.5"
        mgmt/api: "10.108.2.5"
        storage: "10.108.4.3"
        mgmt/corosync: "10.108.2.5"
        cinder/api: "10.108.2.5"
        public/vip: "10.108.1.5"
        swift/replication: "10.108.4.3"
        mgmt/messaging: "10.108.2.5"
        neutron/mesh: "10.108.2.5"
        admin/pxe: "10.109.0.9"
        mongo/db: "10.108.2.5"
        neutron/private: 
        neutron/floating: 
        fw-admin: "10.109.0.9"
        glance/api: "10.108.2.5"
        mgmt/vip: "10.108.2.5"
        murano/api: "10.108.2.5"
        nova/api: "10.108.2.5"
        horizon: "10.108.2.5"
        mgmt/memcache: "10.108.2.5"
        cinder/iscsi: "10.108.4.3"
        ceph/replication: "10.108.4.3"
      user_node_name: "Untitled (6a:e7)"
      node_roles: 
        - controller
      name: node-2
    node-3: &id003
      
      swift_zone: "1"
      uid: "3"
      fqdn: node-3.test.domain.local
      network_roles: 
        keystone/api: "10.108.2.6"
        neutron/api: "10.108.2.6"
        mgmt/database: "10.108.2.6"
        sahara/api: "10.108.2.6"
        heat/api: "10.108.2.6"
        ceilometer/api: "10.108.2.6"
        ex: "10.108.1.6"
        ceph/public: "10.108.2.6"
        ceph/radosgw: "10.108.1.6"
        management: "10.108.2.6"
        swift/api: "10.108.2.6"
        mgmt/api: "10.108.2.6"
        storage: "10.108.4.4"
        mgmt/corosync: "10.108.2.6"
        cinder/api: "10.108.2.6"
        public/vip: "10.108.1.6"
        swift/replication: "10.108.4.4"
        mgmt/messaging: "10.108.2.6"
        neutron/mesh: "10.108.2.6"
        admin/pxe: "10.109.0.9"
        mongo/db: "10.108.2.6"
        neutron/private: 
        neutron/floating: 
        fw-admin: "10.109.0.9"
        glance/api: "10.108.2.6"
        mgmt/vip: "10.108.2.6"
        murano/api: "10.108.2.6"
        nova/api: "10.108.2.6"
        horizon: "10.108.2.6"
        mgmt/memcache: "10.108.2.6"
        cinder/iscsi: "10.108.4.4"
        ceph/replication: "10.108.4.4"
      user_node_name: "Untitled (6a:e7)"
      node_roles: 
        - controller
      name: node-3
  ceph_primary_monitor_node: 
    node-1: *id001
  ceph_rgw_nodes: 
    node-1: *id001
    node-2: *id002
    node-3: *id003
  ceilometer_hash: 
    db_password: cOPq2iRs
    user_password: E7tYGtuu
    metering_secret: "1euklWmj"
    enabled: true
    event_time_to_live: "604800"
    metering_time_to_live: "604800"
    http_timeout: "600"
  ceilometer_nodes: 
    node-1: *id001
    node-2: *id002
    node-3: *id003
  cinder_hash: 
    db_password: g9tWweJY
    user_password: "0Q8lKhCc"
    fixed_key: fb64afea3f59f22d971956f8f773b93482fe3f6465067e5f5337c3e4391b172b
  cinder_nodes: 
    node-1: *id001
    node-2: *id002
    node-3: *id003
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
    node-1: *id001
    node-2: *id002
    node-3: *id003
  debug: true
  default_gateway: 
    - "10.108.1.1"
  deployment_mode: ha_compact
  dns_nameservers: 
    - "8.8.4.4"
    - "8.8.8.8"
  glance_backend: file
  glance_hash: 
    image_cache_max_size: "13868466176"
    user_password: HQQj24u9
    db_password: n1x6qtJg
  glance_known_stores: false
  heat_hash: 
    db_password: ey8Q2Tmb
    user_password: Z2rvUcbg
    enabled: true
    auth_encryption_key: d69db5365b0329c49d01155175f6a45f
    rabbit_password: y4xH2ENh
  heat_roles: 
    - primary-controller
    - controller
  horizon_nodes: 
    node-1: *id001
    node-2: *id002
    node-3: *id003
  node_name: node-1
  idle_timeout: "3600"
  keystone_hash: 
    service_token_off: false
    db_password: rscfOUx4
    admin_token: hrsjAgBf
  manage_volumes: false
  management_network_range: "10.108.2.0/24"
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
    db_password: lDMWrLai
    user_password: jF9pPs9a
    enabled: false
    rabbit_password: P46eXV4F
  murano_roles: 
    - primary-controller
    - controller
  mysql_hash: 
    root_password: NDG84Pcc
    wsrep_password: "4JFDJzqR"
  network_config: 
  network_manager: nova.network.manager.FlatDHCPManager
  network_scheme: 
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
        bridge: br-ex
        name: eth1
      - action: add-port
        bridge: br-mgmt
        name: eth2
      - action: add-port
        bridge: br-storage
        name: eth4
      - action: add-port
        name: eth3.103
    roles: 
      novanetwork/fixed: eth3.103
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
    interfaces: 
      eth4: {}
      eth3: {}
      eth2: {}
      eth1: {}
      eth0: {}
    version: "1.1"
    provider: lnx
    endpoints: 
      eth3.103: 
        IP: none
      br-fw-admin: 
        IP: 
          - "10.108.0.3/24"
      br-storage: 
        IP: 
          - "10.108.4.2/24"
      br-mgmt: 
        IP: 
          - "10.108.2.4/24"
      br-ex: 
        IP: 
          - "10.108.1.4/24"
        gateway: "10.108.1.1"
  network_size: 65536
  neutron_config: {}
  neutron_db_password: 
  neutron_metadata_proxy_secret: 
  neutron_nodes: 
    node-1: *id001
    node-2: *id002
    node-3: *id003
  neutron_user_password: 
  node: *id001
  nodes_hash: 
    - user_node_name: slave-01_controller
      uid: "1"
      public_address: "10.108.1.4"
      internal_netmask: "255.255.255.0"
      fqdn: node-1.test.domain.local
      role: primary-controller
      public_netmask: "255.255.255.0"
      internal_address: "10.108.2.4"
      storage_address: "10.108.4.2"
      swift_zone: "1"
      storage_netmask: "255.255.255.0"
      name: node-1
    - user_node_name: slave-02_controller
      uid: "2"
      public_address: "10.108.1.5"
      internal_netmask: "255.255.255.0"
      fqdn: node-2.test.domain.local
      role: controller
      public_netmask: "255.255.255.0"
      internal_address: "10.108.2.5"
      storage_address: "10.108.4.3"
      swift_zone: "2"
      storage_netmask: "255.255.255.0"
      name: node-2
    - user_node_name: slave-03_controller
      uid: "3"
      public_address: "10.108.1.6"
      internal_netmask: "255.255.255.0"
      fqdn: node-3.test.domain.local
      role: controller
      public_netmask: "255.255.255.0"
      internal_address: "10.108.2.6"
      storage_address: "10.108.4.4"
      swift_zone: "3"
      storage_netmask: "255.255.255.0"
      name: node-3
    - user_node_name: slave-04_compute
      uid: "4"
      public_address: "10.108.1.7"
      internal_netmask: "255.255.255.0"
      fqdn: node-4.test.domain.local
      role: compute
      public_netmask: "255.255.255.0"
      internal_address: "10.108.2.7"
      storage_address: "10.108.4.5"
      swift_zone: "4"
      storage_netmask: "255.255.255.0"
      name: node-4
    - user_node_name: slave-05_mongo
      uid: "5"
      public_address: "10.108.1.8"
      internal_netmask: "255.255.255.0"
      fqdn: node-5.test.domain.local
      role: primary-mongo
      public_netmask: "255.255.255.0"
      internal_address: "10.108.2.8"
      storage_address: "10.108.4.6"
      swift_zone: "5"
      storage_netmask: "255.255.255.0"
      name: node-5
    - user_node_name: slave-06_mongo
      uid: "6"
      public_address: "10.108.1.9"
      internal_netmask: "255.255.255.0"
      fqdn: node-6.test.domain.local
      role: mongo
      public_netmask: "255.255.255.0"
      internal_address: "10.108.2.9"
      storage_address: "10.108.4.7"
      storage_netmask: "255.255.255.0"
      name: node-6
  nova_db_password: "2upYv98H"
  nova_hash: 
    db_password: "2upYv98H"
    user_password: M9mWs2C0
    state_path: /var/lib/nova
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
  private_int: eth3.103
  queue_provider: rabbitmq
  rabbit_ha_queues: true
  rabbit_hash: 
    password: U7sRLche
    user: nova
  node_role: controller
  roles: *id004
  sahara_hash: 
    db_password: LwV220yW
    user_password: xqnj91LB
    enabled: true
  sahara_roles: 
    - primary-controller
    - controller
  sql_connection: "mysql://nova:2upYv98H@10.108.2.2/nova?read_timeout = 6 0"
  storage_hash: 
    iser: false
    volumes_ceph: false
    objects_ceph: false
    ephemeral_ceph: false
    volumes_lvm: true
    images_vcenter: false
    osd_pool_size: "2"
    pg_num: 128
    images_ceph: false
    metadata: 
      weight: 60
      label: Storage
  swift_hash: 
    user_password: MdNIkfj3
  syslog_hash: 
    syslog_port: "514"
    syslog_transport: tcp
    syslog_server: ""
    metadata: 
      weight: 50
      label: Syslog
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
  use_ceilometer: true
  use_monit: false
  use_neutron: false
  use_syslog: true
  vcenter_hash: {}
  verbose: true
  vlan_start: 
  management_vip: "10.108.2.2"
  database_vip: "10.108.2.2"
  service_endpoint: "10.108.2.2"
  public_vip: "10.108.1.2"
  management_vrouter_vip: "10.108.2.3"
  public_vrouter_vip: "10.108.1.3"
  memcache_roles: 
    - primary-controller
    - controller
  swift_master_role: primary-controller
  swift_nodes: 
    node-1: *id001
    node-2: *id002
    node-3: *id003
  swift_proxies: 
    node-1: *id001
    node-2: *id002
    node-3: *id003
  swift_proxy_caches: 
    node-1: *id001
    node-2: *id002
    node-3: *id003
  is_primary_swift_proxy: false
  nova_api_nodes: 
    node-1: *id001
    node-2: *id002
    node-3: *id003
',
  group   => 'root',
  mode    => '0644',
  owner   => 'root',
  path    => '/etc/hiera/globals.yaml',
}

stage { 'main':
  name => 'main',
}

