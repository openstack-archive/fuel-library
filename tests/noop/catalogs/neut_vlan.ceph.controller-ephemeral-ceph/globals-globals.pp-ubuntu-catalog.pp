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
    metadata: 
      weight: 10
      label: Access
    password: admin
    user: admin
    tenant: admin
    email: "admin@localhost"
  amqp_hosts: "10.122.12.3:5673"
  amqp_port: "5673"
  apache_ports: 
    - "80"
    - "8888"
    - "5000"
    - "35357"
  base_mac: "fa:16:3e:00:00:00"
  base_syslog_hash: 
    syslog_port: "514"
    syslog_server: "10.122.10.2"
  ceph_monitor_nodes: 
    node-1: &id001
      
      swift_zone: "1"
      uid: "1"
      fqdn: node-1.domain.local
      network_roles: 
        keystone/api: "10.122.12.3"
        neutron/api: "10.122.12.3"
        mgmt/database: "10.122.12.3"
        sahara/api: "10.122.12.3"
        heat/api: "10.122.12.3"
        ceilometer/api: "10.122.12.3"
        ex: "10.122.11.4"
        ceph/public: "10.122.12.3"
        mgmt/messaging: "10.122.12.3"
        management: "10.122.12.3"
        swift/api: "10.122.12.3"
        storage: "10.122.14.1"
        mgmt/corosync: "10.122.12.3"
        cinder/api: "10.122.12.3"
        public/vip: "10.122.11.4"
        swift/replication: "10.122.14.1"
        ceph/radosgw: "10.122.11.4"
        admin/pxe: "10.122.10.6"
        mongo/db: "10.122.12.3"
        neutron/private: 
        neutron/floating: 
        fw-admin: "10.122.10.6"
        glance/api: "10.122.12.3"
        mgmt/vip: "10.122.12.3"
        murano/api: "10.122.12.3"
        nova/api: "10.122.12.3"
        horizon: "10.122.12.3"
        nova/migration: "10.122.12.3"
        mgmt/memcache: "10.122.12.3"
        cinder/iscsi: "10.122.14.1"
        ceph/replication: "10.122.14.1"
      user_node_name: "Untitled (2c:5e)"
      node_roles: &id002
        
        - ceph-osd
        - primary-controller
      name: node-1
  ceph_primary_monitor_node: 
    node-1: *id001
  ceph_rgw_nodes: 
    node-1: *id001
  ceilometer_hash: 
    db_password: ALNBMs7i
    user_password: "5fXkIlEW"
    metering_secret: k3mrQHsh
    enabled: false
    event_time_to_live: "604800"
    metering_time_to_live: "604800"
    http_timeout: "600"
  ceilometer_nodes: 
    node-1: *id001
  cinder_hash: 
    db_password: te0Sd4Ai
    user_password: HaDqJdMp
    fixed_key: "0842c95fc8bc15d2031d1838ebe2059d16cd39248fc5a1bc74638cfe0c5e8687"
  cinder_nodes: 
    node-1: *id001
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
  debug: false
  default_gateway: 
    - "10.122.11.1"
  deployment_mode: ha_compact
  dns_nameservers: []
  glance_backend: file
  glance_hash: 
    image_cache_max_size: "5368709120"
    user_password: J3jcjTzv
    db_password: vZsiQ0A3
  glance_known_stores: false
  heat_hash: 
    db_password: y9EGLjk9
    user_password: "3SELJ5jn"
    enabled: true
    auth_encryption_key: b200838c57f3e09b2f73df09478a4184
    rabbit_password: JYJzucJF
  heat_roles: 
    - primary-controller
    - controller
  horizon_nodes: 
    node-1: *id001
  node_name: node-1
  idle_timeout: "3600"
  keystone_hash: 
    service_token_off: false
    db_password: "0WzSQMdU"
    admin_token: n7tfrNvt
  manage_volumes: false
  management_network_range: "10.122.12.0/24"
  master_ip: "10.122.10.2"
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
    db_password: SHNCzmlD
    user_password: FAzO3etA
    enabled: false
    rabbit_password: "8yYepd8f"
  murano_roles: 
    - primary-controller
    - controller
  mysql_hash: 
    root_password: sx2tGnw7
    wsrep_password: qEYkmkV7
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
        name: br-ex
      - action: add-br
        name: br-floating
        provider: ovs
      - action: add-patch
        bridges: 
          - br-floating
          - br-ex
        provider: ovs
        mtu: 65000
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
      - action: add-port
        bridge: br-ex
        name: eth1
    roles: 
      murano/api: br-mgmt
      keystone/api: br-mgmt
      neutron/api: br-mgmt
      mgmt/database: br-mgmt
      sahara/api: br-mgmt
      ceilometer/api: br-mgmt
      ex: br-ex
      ceph/public: br-mgmt
      mgmt/messaging: br-mgmt
      management: br-mgmt
      swift/api: br-mgmt
      storage: br-storage
      mgmt/corosync: br-mgmt
      cinder/api: br-mgmt
      public/vip: br-ex
      swift/replication: br-storage
      ceph/radosgw: br-ex
      admin/pxe: br-fw-admin
      mongo/db: br-mgmt
      neutron/private: br-prv
      neutron/floating: br-floating
      fw-admin: br-fw-admin
      glance/api: br-mgmt
      mgmt/vip: br-mgmt
      heat/api: br-mgmt
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
          - "10.122.10.6/24"
      br-prv: 
        IP: none
      br-floating: 
        IP: none
      br-storage: 
        IP: 
          - "10.122.14.1/24"
      br-mgmt: 
        IP: 
          - "10.122.12.3/24"
      br-ex: 
        IP: 
          - "10.122.11.4/24"
        gateway: "10.122.11.1"
  network_size: 
  neutron_config: 
    database: 
      passwd: DVHUmPBa
    keystone: 
      admin_password: muG6m84W
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
          subnet: "10.122.11.0/24"
          floating: "10.122.11.130:10.122.11.254"
          gateway: "10.122.11.1"
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
          subnet: "10.122.13.0/24"
          floating: 
          gateway: "10.122.13.1"
          enable_dhcp: true
        tenant: admin
    metadata: 
      metadata_proxy_shared_secret: P3Hi55Hg
  neutron_db_password: DVHUmPBa
  neutron_metadata_proxy_secret: P3Hi55Hg
  neutron_nodes: 
    node-1: *id001
  neutron_user_password: muG6m84W
  node: *id001
  nodes_hash: 
    - user_node_name: "Untitled (2c:5e)"
      uid: "1"
      public_address: "10.122.11.4"
      internal_netmask: "255.255.255.0"
      fqdn: node-1.domain.local
      role: ceph-osd
      public_netmask: "255.255.255.0"
      internal_address: "10.122.12.3"
      storage_address: "10.122.14.1"
      swift_zone: "1"
      storage_netmask: "255.255.255.0"
      name: node-1
    - user_node_name: "Untitled (2c:5e)"
      uid: "1"
      public_address: "10.122.11.4"
      internal_netmask: "255.255.255.0"
      fqdn: node-1.domain.local
      role: primary-controller
      public_netmask: "255.255.255.0"
      internal_address: "10.122.12.3"
      storage_address: "10.122.14.1"
      swift_zone: "1"
      storage_netmask: "255.255.255.0"
      name: node-1
    - user_node_name: "Untitled (e5:e6)"
      uid: "2"
      internal_netmask: "255.255.255.0"
      fqdn: node-2.domain.local
      role: compute
      internal_address: "10.122.12.6"
      storage_address: "10.122.14.2"
      swift_zone: "2"
      storage_netmask: "255.255.255.0"
      name: node-2
    - user_node_name: "Untitled (50:1e)"
      uid: "3"
      internal_netmask: "255.255.255.0"
      fqdn: node-3.domain.local
      role: ceph-osd
      internal_address: "10.122.12.4"
      storage_address: "10.122.14.4"
      swift_zone: "3"
      storage_netmask: "255.255.255.0"
      name: node-3
    - user_node_name: "Untitled (cb:23)"
      uid: "4"
      internal_netmask: "255.255.255.0"
      fqdn: node-4.domain.local
      role: cinder
      internal_address: "10.122.12.5"
      storage_address: "10.122.14.3"
      swift_zone: "4"
      storage_netmask: "255.255.255.0"
      name: node-4
  nova_db_password: seh61drS
  nova_hash: 
    db_password: seh61drS
    user_password: vhdwzqrw
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
  primary_controller: true
  private_int: 
  queue_provider: rabbitmq
  rabbit_ha_queues: true
  rabbit_hash: 
    password: "06nkQaUt"
    user: nova
  node_role: primary-controller
  roles: *id002
  sahara_hash: 
    db_password: TDie4DCU
    user_password: s3XwKy6C
    enabled: false
  sahara_roles: 
    - primary-controller
    - controller
  sql_connection: "mysql://nova:seh61drS@10.122.12.2/nova?read_timeout = 6 0"
  storage_hash: 
    iser: false
    volumes_ceph: false
    per_pool_pg_nums: 
      compute: 512
      default_pg_num: 64
      volumes: 64
      images: 64
      backups: 64
      ".rgw": 64
    objects_ceph: false
    ephemeral_ceph: true
    volumes_lvm: true
    images_vcenter: false
    osd_pool_size: "2"
    pg_num: 64
    images_ceph: false
    metadata: 
      weight: 60
      label: Storage
  swift_hash: 
    user_password: BmPWa1XA
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
  management_vip: "10.122.12.2"
  database_vip: "10.122.12.2"
  service_endpoint: "10.122.12.2"
  public_vip: "10.122.11.3"
  management_vrouter_vip: "10.122.12.1"
  public_vrouter_vip: "10.122.11.2"
  memcache_roles: 
    - primary-controller
    - controller
  swift_master_role: primary-controller
  swift_nodes: 
    node-1: *id001
  swift_proxies: 
    node-1: *id001
  swift_proxy_caches: 
    node-1: *id001
  is_primary_swift_proxy: true
  nova_api_nodes: 
    node-1: *id001
',
  group   => 'root',
  mode    => '0644',
  owner   => 'root',
  path    => '/etc/hiera/globals.yaml',
}

stage { 'main':
  name => 'main',
}

