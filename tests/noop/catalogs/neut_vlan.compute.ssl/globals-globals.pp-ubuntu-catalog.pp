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
    password: admin
    user: admin
    tenant: admin
    metadata: 
      weight: 10
      label: Access
  amqp_hosts: "10.122.7.1:5673, 10.122.7.4:5673, 10.122.7.5:5673"
  amqp_port: "5673"
  apache_ports: 
    - "80"
    - "8888"
    - "5000"
    - "35357"
  base_mac: "fa:16:3e:00:00:00"
  base_syslog_hash: 
    syslog_port: "514"
    syslog_server: "10.122.5.2"
  ceph_monitor_nodes: 
    node-1: &id001
      
      swift_zone: "1"
      uid: "1"
      fqdn: node-1.domain.local
      network_roles: 
        keystone/api: "10.122.7.1"
        neutron/api: "10.122.7.1"
        mgmt/database: "10.122.7.1"
        sahara/api: "10.122.7.1"
        heat/api: "10.122.7.1"
        ceilometer/api: "10.122.7.1"
        ex: "10.122.6.2"
        ceph/public: "10.122.7.1"
        mgmt/messaging: "10.122.7.1"
        management: "10.122.7.1"
        swift/api: "10.122.7.1"
        storage: "10.122.9.1"
        mgmt/corosync: "10.122.7.1"
        cinder/api: "10.122.7.1"
        public/vip: "10.122.6.2"
        swift/replication: "10.122.9.1"
        ceph/radosgw: "10.122.6.2"
        admin/pxe: "10.122.5.3"
        mongo/db: "10.122.7.1"
        neutron/private: 
        neutron/floating: 
        fw-admin: "10.122.5.3"
        glance/api: "10.122.7.1"
        mgmt/vip: "10.122.7.1"
        murano/api: "10.122.7.1"
        nova/api: "10.122.7.1"
        horizon: "10.122.7.1"
        nova/migration: "10.122.7.1"
        mgmt/memcache: "10.122.7.1"
        cinder/iscsi: "10.122.9.1"
        ceph/replication: "10.122.9.1"
      user_node_name: "Untitled (d8:bb)"
      node_roles: 
        - cinder
        - primary-controller
      name: node-1
    node-3: &id002
      
      swift_zone: "3"
      uid: "3"
      fqdn: node-3.domain.local
      network_roles: 
        keystone/api: "10.122.7.5"
        neutron/api: "10.122.7.5"
        mgmt/database: "10.122.7.5"
        sahara/api: "10.122.7.5"
        heat/api: "10.122.7.5"
        ceilometer/api: "10.122.7.5"
        ex: "10.122.6.3"
        ceph/public: "10.122.7.5"
        mgmt/messaging: "10.122.7.5"
        management: "10.122.7.5"
        swift/api: "10.122.7.5"
        storage: "10.122.9.2"
        mgmt/corosync: "10.122.7.5"
        cinder/api: "10.122.7.5"
        public/vip: "10.122.6.3"
        swift/replication: "10.122.9.2"
        ceph/radosgw: "10.122.6.3"
        admin/pxe: "10.122.5.6"
        mongo/db: "10.122.7.5"
        neutron/private: 
        neutron/floating: 
        fw-admin: "10.122.5.6"
        glance/api: "10.122.7.5"
        mgmt/vip: "10.122.7.5"
        murano/api: "10.122.7.5"
        nova/api: "10.122.7.5"
        horizon: "10.122.7.5"
        nova/migration: "10.122.7.5"
        mgmt/memcache: "10.122.7.5"
        cinder/iscsi: "10.122.9.2"
        ceph/replication: "10.122.9.2"
      user_node_name: "Untitled (03:15)"
      node_roles: 
        - cinder
        - controller
      name: node-3
    node-2: &id003
      
      swift_zone: "2"
      uid: "2"
      fqdn: node-2.domain.local
      network_roles: 
        keystone/api: "10.122.7.4"
        neutron/api: "10.122.7.4"
        mgmt/database: "10.122.7.4"
        sahara/api: "10.122.7.4"
        heat/api: "10.122.7.4"
        ceilometer/api: "10.122.7.4"
        ex: "10.122.6.4"
        ceph/public: "10.122.7.4"
        mgmt/messaging: "10.122.7.4"
        management: "10.122.7.4"
        swift/api: "10.122.7.4"
        storage: "10.122.9.3"
        mgmt/corosync: "10.122.7.4"
        cinder/api: "10.122.7.4"
        public/vip: "10.122.6.4"
        swift/replication: "10.122.9.3"
        ceph/radosgw: "10.122.6.4"
        admin/pxe: "10.122.5.7"
        mongo/db: "10.122.7.4"
        neutron/private: 
        neutron/floating: 
        fw-admin: "10.122.5.7"
        glance/api: "10.122.7.4"
        mgmt/vip: "10.122.7.4"
        murano/api: "10.122.7.4"
        nova/api: "10.122.7.4"
        horizon: "10.122.7.4"
        nova/migration: "10.122.7.4"
        mgmt/memcache: "10.122.7.4"
        cinder/iscsi: "10.122.9.3"
        ceph/replication: "10.122.9.3"
      user_node_name: "Untitled (68:63)"
      node_roles: 
        - cinder
        - controller
      name: node-2
  ceph_primary_monitor_node: 
    node-1: *id001
  ceph_rgw_nodes: 
    node-1: *id001
    node-3: *id002
    node-2: *id003
  ceilometer_hash: 
    db_password: HUn68NQb
    user_password: ycMeNdmo
    metering_secret: zjAKZxtd
    enabled: false
    event_time_to_live: "604800"
    metering_time_to_live: "604800"
    http_timeout: "600"
  ceilometer_nodes: 
    node-1: *id001
    node-3: *id002
    node-2: *id003
  cinder_hash: 
    db_password: qeN6frZT
    user_password: "7Al0iWfl"
    fixed_key: "264ecf97cf69264f775e549fe5fd1ce3db6a92df94d37745819892803a83b19c"
  cinder_nodes: 
    node-1: *id001
    node-3: *id002
    node-2: *id003
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
    node-3: *id002
    node-2: *id003
  debug: false
  default_gateway: 
    - "10.122.5.2"
  deployment_mode: ha_compact
  dns_nameservers: []
  glance_backend: file
  glance_hash: 
    image_cache_max_size: "5368709120"
    user_password: DztOMLWg
    db_password: LtDxFLyX
  glance_known_stores: false
  heat_hash: 
    db_password: GqzWSxBW
    user_password: uMxK47eJ
    enabled: true
    auth_encryption_key: "9431f2b16d26488b896e64d236953521"
    rabbit_password: jnXk99nV
  heat_roles: 
    - primary-controller
    - controller
  horizon_nodes: 
    node-1: *id001
    node-3: *id002
    node-2: *id003
  node_name: node-5
  idle_timeout: "3600"
  keystone_hash: 
    service_token_off: false
    db_password: H4N630IH
    admin_token: cKHHVACg
  manage_volumes: false
  management_network_range: "10.122.7.0/24"
  master_ip: "10.122.5.2"
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
    db_password: gjBrHFFZ
    user_password: crLmJ5b0
    enabled: false
    rabbit_password: ra45kjwS
  murano_roles: 
    - primary-controller
    - controller
  mysql_hash: 
    root_password: PBmaN2YX
    wsrep_password: FsatnsoY
  network_config: 
  network_manager: 
  network_scheme: 
    transformations: 
      - action: add-br
        name: br-fw-admin
      - action: add-br
        name: br-mgmt
      - action: add-br
        name: br-storage
      - action: add-br
        name: br-prv
        provider: ovs
      - action: add-patch
        bridges: 
          - br-prv
          - br-fw-admin
        provider: ovs
        mtu: 65000
      - action: add-port
        bridge: br-fw-admin
        name: eth0
      - action: add-port
        bridge: br-mgmt
        name: eth0.101
      - action: add-port
        bridge: br-storage
        name: eth0.102
    roles: 
      murano/api: br-mgmt
      keystone/api: br-mgmt
      neutron/api: br-mgmt
      mgmt/database: br-mgmt
      sahara/api: br-mgmt
      ceilometer/api: br-mgmt
      ceph/public: br-mgmt
      mgmt/messaging: br-mgmt
      management: br-mgmt
      swift/api: br-mgmt
      storage: br-storage
      mgmt/corosync: br-mgmt
      cinder/api: br-mgmt
      swift/replication: br-storage
      admin/pxe: br-fw-admin
      mongo/db: br-mgmt
      neutron/private: br-prv
      fw-admin: br-fw-admin
      glance/api: br-mgmt
      heat/api: br-mgmt
      mgmt/vip: br-mgmt
      nova/api: br-mgmt
      horizon: br-mgmt
      nova/migration: br-mgmt
      mgmt/memcache: br-mgmt
      cinder/iscsi: br-storage
      ceph/replication: br-storage
    interfaces: 
      eth4: 
        vendor_specific: 
          driver: e1000
          bus_info: "0000:00:07.0"
      eth3: 
        vendor_specific: 
          driver: e1000
          bus_info: "0000:00:06.0"
      eth2: 
        vendor_specific: 
          driver: e1000
          bus_info: "0000:00:05.0"
      eth1: 
        vendor_specific: 
          driver: e1000
          bus_info: "0000:00:04.0"
      eth0: 
        vendor_specific: 
          driver: e1000
          bus_info: "0000:00:03.0"
    version: "1.1"
    provider: lnx
    endpoints: 
      br-fw-admin: 
        IP: 
          - "10.122.5.4/24"
        gateway: "10.122.5.2"
      br-storage: 
        IP: 
          - "10.122.9.4/24"
      br-mgmt: 
        IP: 
          - "10.122.7.3/24"
      br-prv: 
        IP: none
  network_size: 
  neutron_config: 
    database: 
      passwd: bnQfjm1A
    keystone: 
      admin_password: glXcjTAY
    L3: 
      use_namespaces: true
    L2: 
      phys_nets: 
        physnet2: 
          bridge: br-prv
          vlan_range: "1000:1030"
      base_mac: "fa:16:3e:00:00:00"
      segmentation_type: vlan
    predefined_networks: 
      net04_ext: 
        shared: false
        L2: 
          network_type: local
          router_ext: true
          physnet: 
          segment_id: 
        L3: 
          nameservers: []
          subnet: "10.122.6.0/24"
          floating: "10.122.6.130:10.122.6.254"
          gateway: "10.122.6.1"
          enable_dhcp: false
        tenant: admin
      net04: 
        shared: false
        L2: 
          network_type: vlan
          router_ext: false
          physnet: physnet2
          segment_id: 
        L3: 
          nameservers: 
            - "8.8.4.4"
            - "8.8.8.8"
          subnet: "10.122.8.0/24"
          floating: 
          gateway: "10.122.8.1"
          enable_dhcp: true
        tenant: admin
    metadata: 
      metadata_proxy_shared_secret: orn88mVY
  neutron_db_password: bnQfjm1A
  neutron_metadata_proxy_secret: orn88mVY
  neutron_nodes: 
    node-1: *id001
    node-3: *id002
    node-2: *id003
  neutron_user_password: glXcjTAY
  node: 
    swift_zone: "5"
    uid: "5"
    fqdn: node-5.domain.local
    network_roles: 
      murano/api: "10.122.7.3"
      keystone/api: "10.122.7.3"
      neutron/api: "10.122.7.3"
      mgmt/database: "10.122.7.3"
      sahara/api: "10.122.7.3"
      ceilometer/api: "10.122.7.3"
      ceph/public: "10.122.7.3"
      mgmt/messaging: "10.122.7.3"
      management: "10.122.7.3"
      swift/api: "10.122.7.3"
      storage: "10.122.9.4"
      mgmt/corosync: "10.122.7.3"
      cinder/api: "10.122.7.3"
      swift/replication: "10.122.9.4"
      admin/pxe: "10.122.5.4"
      mongo/db: "10.122.7.3"
      neutron/private: 
      neutron/floating: 
      fw-admin: "10.122.5.4"
      glance/api: "10.122.7.3"
      heat/api: "10.122.7.3"
      mgmt/vip: "10.122.7.3"
      nova/api: "10.122.7.3"
      horizon: "10.122.7.3"
      nova/migration: "10.122.7.3"
      mgmt/memcache: "10.122.7.3"
      cinder/iscsi: "10.122.9.4"
      ceph/replication: "10.122.9.4"
    user_node_name: "Untitled (2a:ee)"
    node_roles: &id004
      
      - compute
    name: node-5
  nodes_hash: 
    - user_node_name: "Untitled (d8:bb)"
      uid: "1"
      public_address: "10.122.6.2"
      internal_netmask: "255.255.255.0"
      fqdn: node-1.domain.local
      role: cinder
      public_netmask: "255.255.255.0"
      internal_address: "10.122.7.1"
      storage_address: "10.122.9.1"
      swift_zone: "1"
      storage_netmask: "255.255.255.0"
      name: node-1
    - user_node_name: "Untitled (d8:bb)"
      uid: "1"
      public_address: "10.122.6.2"
      internal_netmask: "255.255.255.0"
      fqdn: node-1.domain.local
      role: primary-controller
      public_netmask: "255.255.255.0"
      internal_address: "10.122.7.1"
      storage_address: "10.122.9.1"
      swift_zone: "1"
      storage_netmask: "255.255.255.0"
      name: node-1
    - user_node_name: "Untitled (68:63)"
      uid: "2"
      public_address: "10.122.6.4"
      internal_netmask: "255.255.255.0"
      fqdn: node-2.domain.local
      role: cinder
      public_netmask: "255.255.255.0"
      internal_address: "10.122.7.4"
      storage_address: "10.122.9.3"
      swift_zone: "2"
      storage_netmask: "255.255.255.0"
      name: node-2
    - user_node_name: "Untitled (68:63)"
      uid: "2"
      public_address: "10.122.6.4"
      internal_netmask: "255.255.255.0"
      fqdn: node-2.domain.local
      role: controller
      public_netmask: "255.255.255.0"
      internal_address: "10.122.7.4"
      storage_address: "10.122.9.3"
      swift_zone: "2"
      storage_netmask: "255.255.255.0"
      name: node-2
    - user_node_name: "Untitled (03:15)"
      uid: "3"
      public_address: "10.122.6.3"
      internal_netmask: "255.255.255.0"
      fqdn: node-3.domain.local
      role: cinder
      public_netmask: "255.255.255.0"
      internal_address: "10.122.7.5"
      storage_address: "10.122.9.2"
      swift_zone: "3"
      storage_netmask: "255.255.255.0"
      name: node-3
    - user_node_name: "Untitled (03:15)"
      uid: "3"
      public_address: "10.122.6.3"
      internal_netmask: "255.255.255.0"
      fqdn: node-3.domain.local
      role: controller
      public_netmask: "255.255.255.0"
      internal_address: "10.122.7.5"
      storage_address: "10.122.9.2"
      swift_zone: "3"
      storage_netmask: "255.255.255.0"
      name: node-3
    - user_node_name: "Untitled (a7:46)"
      uid: "4"
      internal_netmask: "255.255.255.0"
      fqdn: node-4.domain.local
      role: compute
      internal_address: "10.122.7.2"
      storage_address: "10.122.9.5"
      swift_zone: "4"
      storage_netmask: "255.255.255.0"
      name: node-4
    - user_node_name: "Untitled (2a:ee)"
      uid: "5"
      internal_netmask: "255.255.255.0"
      fqdn: node-5.domain.local
      role: compute
      internal_address: "10.122.7.3"
      storage_address: "10.122.9.4"
      swift_zone: "5"
      storage_netmask: "255.255.255.0"
      name: node-5
  nova_db_password: of31Rxsy
  nova_hash: 
    db_password: of31Rxsy
    user_password: n0KfayKg
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
  novanetwork_params: {}
  num_networks: 
  openstack_version: "2015.1.0-8.0"
  primary_controller: false
  private_int: 
  queue_provider: rabbitmq
  rabbit_ha_queues: true
  rabbit_hash: 
    password: WYcvKQyZ
    user: nova
  node_role: compute
  roles: *id004
  sahara_hash: 
    db_password: dfoFKl7u
    user_password: jYjxogYn
    enabled: false
  sahara_roles: 
    - primary-controller
    - controller
  sql_connection: "mysql://nova:of31Rxsy@10.122.7.7/nova?read_timeout = 6 0"
  storage_hash: 
    iser: false
    volumes_ceph: false
    per_pool_pg_nums: 
      compute: 128
      default_pg_num: 128
      volumes: 128
      images: 128
      backups: 128
      ".rgw": 128
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
    user_password: zr0zBVgi
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
  use_ceilometer: false
  use_monit: false
  use_neutron: true
  use_syslog: true
  vcenter_hash: {}
  verbose: true
  vlan_start: 
  management_vip: "10.122.7.7"
  database_vip: "10.122.7.7"
  service_endpoint: "10.122.7.7"
  public_vip: "10.122.6.6"
  management_vrouter_vip: "10.122.7.6"
  public_vrouter_vip: "10.122.6.5"
  memcache_roles: 
    - primary-controller
    - controller
  swift_master_role: primary-controller
  swift_nodes: 
    node-1: *id001
    node-3: *id002
    node-2: *id003
  swift_proxies: 
    node-1: *id001
    node-3: *id002
    node-2: *id003
  swift_proxy_caches: 
    node-1: *id001
    node-3: *id002
    node-2: *id003
  is_primary_swift_proxy: false
  nova_api_nodes: 
    node-1: *id001
    node-3: *id002
    node-2: *id003
',
  group   => 'root',
  mode    => '0644',
  owner   => 'root',
  path    => '/etc/hiera/globals.yaml',
}

stage { 'main':
  name => 'main',
}

