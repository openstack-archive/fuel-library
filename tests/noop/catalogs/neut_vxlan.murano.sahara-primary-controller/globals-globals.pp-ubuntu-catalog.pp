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
  amqp_hosts: "192.168.0.2:5673, 192.168.0.4:5673, 192.168.0.3:5673"
  amqp_port: "5673"
  apache_ports: 
    - "80"
    - "8888"
    - "5000"
    - "35357"
  base_mac: "fa:16:3e:00:00:00"
  base_syslog_hash: 
    syslog_port: "514"
    syslog_server: "10.108.0.2"
  ceph_monitor_nodes: 
    node-128: &id001
      
      swift_zone: "1"
      uid: "128"
      fqdn: node-128.test.domain.local
      network_roles: 
        keystone/api: "192.168.0.2"
        neutron/api: "192.168.0.2"
        mgmt/database: "192.168.0.2"
        sahara/api: "192.168.0.2"
        heat/api: "192.168.0.2"
        ceilometer/api: "192.168.0.2"
        ex: "172.16.0.2"
        ceph/public: "192.168.0.2"
        ceph/radosgw: "172.16.0.2"
        management: "192.168.0.2"
        swift/api: "192.168.0.2"
        mgmt/api: "192.168.0.2"
        storage: "192.168.1.2"
        mgmt/corosync: "192.168.0.2"
        cinder/api: "192.168.0.2"
        public/vip: "172.16.0.2"
        swift/replication: "192.168.1.2"
        mgmt/messaging: "192.168.0.2"
        neutron/mesh: "192.168.0.2"
        admin/pxe: "10.108.0.3"
        mongo/db: "192.168.0.2"
        neutron/private: 
        neutron/floating: 
        fw-admin: "10.108.0.3"
        glance/api: "192.168.0.2"
        mgmt/vip: "192.168.0.2"
        murano/api: "192.168.0.2"
        nova/api: "192.168.0.2"
        horizon: "192.168.0.2"
        mgmt/memcache: "192.168.0.2"
        cinder/iscsi: "192.168.1.2"
        ceph/replication: "192.168.1.2"
      user_node_name: "Untitled (6a:e7)"
      node_roles: &id004
        
        - primary-controller
      name: node-128
    node-129: &id002
      
      swift_zone: "1"
      uid: "129"
      fqdn: node-129.test.domain.local
      network_roles: 
        keystone/api: "192.168.0.3"
        neutron/api: "192.168.0.3"
        mgmt/database: "192.168.0.3"
        sahara/api: "192.168.0.3"
        heat/api: "192.168.0.3"
        ceilometer/api: "192.168.0.3"
        ex: "172.16.0.3"
        ceph/public: "192.168.0.3"
        ceph/radosgw: "172.16.0.3"
        management: "192.168.0.3"
        swift/api: "192.168.0.3"
        mgmt/api: "192.168.0.3"
        storage: "192.168.1.3"
        mgmt/corosync: "192.168.0.3"
        cinder/api: "192.168.0.3"
        public/vip: "172.16.0.3"
        swift/replication: "192.168.1.3"
        mgmt/messaging: "192.168.0.3"
        neutron/mesh: "192.168.0.3"
        admin/pxe: "10.108.0.6"
        mongo/db: "192.168.0.3"
        neutron/private: 
        neutron/floating: 
        fw-admin: "10.108.0.6"
        glance/api: "192.168.0.3"
        mgmt/vip: "192.168.0.3"
        murano/api: "192.168.0.3"
        nova/api: "192.168.0.3"
        horizon: "192.168.0.3"
        mgmt/memcache: "192.168.0.3"
        cinder/iscsi: "192.168.1.3"
        ceph/replication: "192.168.1.3"
      user_node_name: "Untitled (6a:e7)"
      node_roles: 
        - controller
      name: node-129
    node-131: &id003
      
      swift_zone: "1"
      uid: "131"
      fqdn: node-131.test.domain.local
      network_roles: 
        keystone/api: "192.168.0.4"
        neutron/api: "192.168.0.4"
        mgmt/database: "192.168.0.4"
        sahara/api: "192.168.0.4"
        heat/api: "192.168.0.4"
        ceilometer/api: "192.168.0.4"
        ex: "172.16.0.4"
        ceph/public: "192.168.0.4"
        ceph/radosgw: "172.16.0.4"
        management: "192.168.0.4"
        swift/api: "192.168.0.4"
        mgmt/api: "192.168.0.4"
        storage: "192.168.1.4"
        mgmt/corosync: "192.168.0.4"
        cinder/api: "192.168.0.4"
        public/vip: "172.16.0.4"
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
        - controller
      name: node-131
  ceph_primary_monitor_node: 
    node-128: *id001
  ceph_rgw_nodes: 
    node-128: *id001
    node-129: *id002
    node-131: *id003
  ceilometer_hash: 
    db_password: ZcffCIm5
    enabled: false
    metering_secret: "7aqxzabx"
    user_password: FQUfTQ6a
    event_time_to_live: "604800"
    metering_time_to_live: "604800"
    http_timeout: "600"
  ceilometer_nodes: 
    node-128: *id001
    node-129: *id002
    node-131: *id003
  cinder_hash: 
    db_password: "71kNkN9U"
    fixed_key: "0ded0202e2a355df942df2bacbaba992658a0345f68f2db6e1bdb6dbb8f682cf"
    user_password: O2st17AP
  cinder_nodes: 
    node-128: *id001
    node-129: *id002
    node-131: *id003
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
    node-128: *id001
    node-129: *id002
    node-131: *id003
  debug: false
  default_gateway: 
    - "172.16.0.1"
  deployment_mode: ha_compact
  dns_nameservers: []
  glance_backend: file
  glance_hash: 
    db_password: "0UYCFNfc"
    image_cache_max_size: "13868466176"
    user_password: "94lWbeNn"
  glance_known_stores: false
  heat_hash: 
    auth_encryption_key: "8edb899a7e81e56abe51639880aa32dd"
    db_password: AuaPc3Yq
    enabled: true
    rabbit_password: Nmn2wr9S
    user_password: EWJfBLJ9
  heat_roles: 
    - primary-controller
    - controller
  horizon_nodes: 
    node-128: *id001
    node-129: *id002
    node-131: *id003
  node_name: node-128
  idle_timeout: "3600"
  keystone_hash: 
    service_token_off: false
    admin_token: "0be9G8hj"
    db_password: "32TWl29R"
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
    db_password: R3SuvZbh
    enabled: true
    rabbit_password: ZNdTAgF3
    user_password: xP8WtHQw
  murano_roles: 
    - primary-controller
    - controller
  mysql_hash: 
    root_password: Lz18BpbQ
    wsrep_password: JrlrVOHu
  network_config: 
  network_manager: 
  network_scheme: 
    endpoints: 
      br-ex: 
        IP: 
          - "172.16.0.2/24"
        gateway: "172.16.0.1"
        vendor_specific: 
          phy_interfaces: 
            - eth1
      br-floating: 
        IP: none
      br-fw-admin: 
        IP: 
          - "10.108.0.3/24"
      br-mgmt: 
        IP: 
          - "192.168.0.2/24"
        vendor_specific: 
          phy_interfaces: 
            - eth0
          vlans: 101
      br-storage: 
        IP: 
          - "192.168.1.2/24"
        vendor_specific: 
          phy_interfaces: 
            - eth0
          vlans: 102
    interfaces: 
      eth0: 
        vendor_specific: 
          bus_info: "0000:00:03.0"
          driver: e1000
      eth1: 
        vendor_specific: 
          bus_info: "0000:00:04.0"
          driver: e1000
      eth2: 
        vendor_specific: 
          bus_info: "0000:00:05.0"
          driver: e1000
      eth3: 
        vendor_specific: 
          bus_info: "0000:00:06.0"
          driver: e1000
      eth4: 
        vendor_specific: 
          bus_info: "0000:00:07.0"
          driver: e1000
    provider: lnx
    roles: 
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
        name: br-mgmt
      - action: add-br
        name: br-storage
      - action: add-br
        name: br-ex
      - action: add-br
        name: br-floating
        provider: ovs
      - action: add-patch
        bridges: 
          - br-floating
          - br-ex
        provider: ovs
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
    version: "1.1"
  network_size: 
  neutron_config: 
    L2: 
      base_mac: "fa:16:3e:00:00:00"
      phys_nets: {}
      segmentation_type: tun
      tunnel_id_ranges: "2:65535"
    L3: 
      use_namespaces: true
    database: 
      passwd: QRpCfPk8
    keystone: 
      admin_password: oT56DSZF
    metadata: 
      metadata_proxy_shared_secret: fp618p5V
    predefined_networks: 
      net04: 
        L2: 
          network_type: vxlan
          physnet: 
          router_ext: false
          segment_id: 
        L3: 
          enable_dhcp: true
          floating: 
          gateway: "192.168.111.1"
          nameservers: 
            - "8.8.4.4"
            - "8.8.8.8"
          subnet: "192.168.111.0/24"
        shared: false
        tenant: admin
      net04_ext: 
        L2: 
          network_type: local
          physnet: 
          router_ext: true
          segment_id: 
        L3: 
          enable_dhcp: false
          floating: "172.16.0.130:172.16.0.254"
          gateway: "172.16.0.1"
          nameservers: []
          subnet: "172.16.0.0/24"
        shared: false
        tenant: admin
  neutron_db_password: QRpCfPk8
  neutron_metadata_proxy_secret: fp618p5V
  neutron_nodes: 
    node-128: *id001
    node-129: *id002
    node-131: *id003
  neutron_user_password: oT56DSZF
  node: *id001
  nodes_hash: 
    - fqdn: node-118.test.domain.local
      internal_address: "192.168.0.1"
      internal_netmask: "255.255.255.0"
      name: node-118
      role: cinder
      storage_address: "192.168.1.1"
      storage_netmask: "255.255.255.0"
      swift_zone: "118"
      uid: "118"
      user_node_name: "Untitled (1d:4b)"
    - fqdn: node-128.test.domain.local
      internal_address: "192.168.0.2"
      internal_netmask: "255.255.255.0"
      name: node-128
      public_address: "172.16.0.2"
      public_netmask: "255.255.255.0"
      role: primary-controller
      storage_address: "192.168.1.2"
      storage_netmask: "255.255.255.0"
      swift_zone: "128"
      uid: "128"
      user_node_name: "Untitled (6f:9d)"
    - fqdn: node-129.test.domain.local
      internal_address: "192.168.0.3"
      internal_netmask: "255.255.255.0"
      name: node-129
      public_address: "172.16.0.3"
      public_netmask: "255.255.255.0"
      role: controller
      storage_address: "192.168.1.3"
      storage_netmask: "255.255.255.0"
      swift_zone: "129"
      uid: "129"
      user_node_name: "Untitled (74:27)"
    - fqdn: node-131.test.domain.local
      internal_address: "192.168.0.4"
      internal_netmask: "255.255.255.0"
      name: node-131
      public_address: "172.16.0.4"
      public_netmask: "255.255.255.0"
      role: controller
      storage_address: "192.168.1.4"
      storage_netmask: "255.255.255.0"
      swift_zone: "131"
      uid: "131"
      user_node_name: "Untitled (34:45)"
    - fqdn: node-132.test.domain.local
      internal_address: "192.168.0.5"
      internal_netmask: "255.255.255.0"
      name: node-132
      role: compute
      storage_address: "192.168.1.5"
      storage_netmask: "255.255.255.0"
      swift_zone: "132"
      uid: "132"
      user_node_name: "Untitled (18:c9)"
  nova_db_password: mqnsUMgC
  nova_hash: 
    db_password: mqnsUMgC
    state_path: /var/lib/nova
    user_password: fj4wVCEs
    vncproxy_protocol: https
  nova_rate_limits: 
    POST: "100000"
    POST_SERVERS: "100000"
    PUT: "1000"
    GET: "100000"
    DELETE: "100000"
  nova_report_interval: "60"
  nova_service_down_time: "180"
  novanetwork_params: {}
  num_networks: 
  openstack_version: "2014.2-6.1"
  primary_controller: true
  private_int: 
  queue_provider: rabbitmq
  rabbit_ha_queues: true
  rabbit_hash: 
    password: c7fQJeSe
    user: nova
  node_role: primary-controller
  roles: *id004
  sahara_hash: 
    db_password: f0jl4v47
    enabled: true
    user_password: pJc2zAOx
  sahara_roles: 
    - primary-controller
    - controller
  sql_connection: "mysql://nova:mqnsUMgC@192.168.0.2/nova?read_timeout = 6 0"
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
    user_password: BP92J6tg
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
  use_neutron: true
  use_syslog: true
  vcenter_hash: {}
  verbose: true
  vlan_start: 
  management_vip: "192.168.0.2"
  database_vip: "192.168.0.2"
  service_endpoint: "192.168.0.2"
  public_vip: "10.109.1.2"
  management_vrouter_vip: "192.168.0.3"
  public_vrouter_vip: "10.109.1.3"
  memcache_roles: 
    - primary-controller
    - controller
  swift_master_role: primary-controller
  swift_nodes: 
    node-128: *id001
    node-129: *id002
    node-131: *id003
  swift_proxies: 
    node-128: *id001
    node-129: *id002
    node-131: *id003
  swift_proxy_caches: 
    node-128: *id001
    node-129: *id002
    node-131: *id003
  is_primary_swift_proxy: true
  nova_api_nodes: 
    node-128: *id001
    node-129: *id002
    node-131: *id003
',
  group   => 'root',
  mode    => '0644',
  owner   => 'root',
  path    => '/etc/hiera/globals.yaml',
}

stage { 'main':
  name => 'main',
}

