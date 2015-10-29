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
  amqp_hosts: "192.168.0.3:5673"
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
    node-125: &id001
      
      swift_zone: "1"
      uid: "125"
      fqdn: node-125.test.domain.local
      network_roles: 
        keystone/api: "192.168.0.3"
        neutron/api: "192.168.0.3"
        mgmt/database: "192.168.0.3"
        sahara/api: "192.168.0.3"
        heat/api: "192.168.0.3"
        ceilometer/api: "192.168.0.3"
        ex: "172.16.0.2"
        ceph/public: "192.168.0.3"
        ceph/radosgw: "172.16.0.2"
        management: "192.168.0.3"
        swift/api: "192.168.0.3"
        mgmt/api: "192.168.0.3"
        storage: "192.168.1.3"
        mgmt/corosync: "192.168.0.3"
        cinder/api: "192.168.0.3"
        public/vip: "172.16.0.2"
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
      node_roles: 
        - primary-controller
      name: node-125
  ceph_primary_monitor_node: 
    node-125: *id001
  ceph_rgw_nodes: 
    node-125: *id001
  ceilometer_hash: 
    db_password: Toe5phw4
    enabled: true
    metering_secret: tHq2rcoq
    user_password: WBfBSo6U
    event_time_to_live: "604800"
    metering_time_to_live: "604800"
    http_timeout: "600"
  ceilometer_nodes: 
    node-125: *id001
  cinder_hash: 
    db_password: trj609V8
    fixed_key: "7883d66c643ce9a508ebcd4cd5516fc98814a11276bc98c4e8e671188b54e941"
    user_password: sJRfG0GP
  cinder_nodes: 
    node-125: *id001
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
    node-125: *id001
  debug: false
  default_gateway: 
    - "192.168.0.7"
  deployment_mode: ha_compact
  dns_nameservers: []
  glance_backend: ceph
  glance_hash: 
    db_password: "385SUUrC"
    image_cache_max_size: "0"
    user_password: A9KgbnX6
  glance_known_stores: 
    - glance.store.rbd.Store
    - glance.store.http.Store
  heat_hash: 
    auth_encryption_key: "2604abefbdf5043f07e989af10f6caba"
    db_password: NTeyraV2
    enabled: true
    rabbit_password: ReVt6ZKQ
    user_password: tryL79Yl
  heat_roles: 
    - primary-controller
    - controller
  horizon_nodes: 
    node-125: *id001
  node_name: node-121
  idle_timeout: "3600"
  keystone_hash: 
    service_token_off: false
    admin_token: UxFQFw3m
    db_password: e4Op1FQB
  manage_volumes: ceph
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
    db_password: "7I6NRZcB"
    enabled: false
    rabbit_password: X4GK4R7f
    user_password: nuCELy8q
  murano_roles: 
    - primary-controller
    - controller
  mysql_hash: 
    root_password: "5eqwkxY3"
    wsrep_password: sFMiVJ7I
  network_config: 
  network_manager: 
  network_scheme: 
    endpoints: 
      br-fw-admin: 
        IP: 
          - "10.108.0.4/24"
      br-mgmt: 
        IP: 
          - "192.168.0.1/24"
        gateway: "192.168.0.7"
        vendor_specific: 
          phy_interfaces: 
            - eth0
          vlans: 101
      br-prv: 
        IP: none
        vendor_specific: 
          phy_interfaces: 
            - eth0
          vlans: "1000:1030"
      br-storage: 
        IP: 
          - "192.168.1.1/24"
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
        name: br-prv
        provider: ovs
      - action: add-patch
        bridges: 
          - br-prv
          - br-fw-admin
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
    version: "1.1"
  network_size: 
  neutron_config: 
    L2: 
      base_mac: "fa:16:3e:00:00:00"
      phys_nets: 
        physnet2: 
          bridge: br-prv
          vlan_range: "1000:1030"
      segmentation_type: vlan
    L3: 
      use_namespaces: true
    database: 
      passwd: zOXpcc6c
    keystone: 
      admin_password: XgdPodA7
    metadata: 
      metadata_proxy_shared_secret: QU11ydS2
    predefined_networks: 
      net04: 
        L2: 
          network_type: vlan
          physnet: physnet2
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
  neutron_db_password: zOXpcc6c
  neutron_metadata_proxy_secret: QU11ydS2
  neutron_nodes: 
    node-125: *id001
  neutron_user_password: XgdPodA7
  node: 
    swift_zone: "1"
    uid: "121"
    fqdn: node-121.test.domain.local
    network_roles: 
      keystone/api: "192.168.0.1"
      neutron/api: "192.168.0.1"
      mgmt/database: "192.168.0.1"
      sahara/api: "192.168.0.1"
      heat/api: "192.168.0.1"
      ceilometer/api: "192.168.0.1"
      ex: 
      ceph/public: "192.168.0.1"
      ceph/radosgw: 
      management: "192.168.0.1"
      swift/api: "192.168.0.1"
      mgmt/api: "192.168.0.1"
      storage: "192.168.1.1"
      mgmt/corosync: "192.168.0.1"
      cinder/api: "192.168.0.1"
      public/vip: 
      swift/replication: "192.168.1.1"
      mgmt/messaging: "192.168.0.1"
      neutron/mesh: "192.168.0.1"
      admin/pxe: "10.109.0.9"
      mongo/db: "192.168.0.1"
      neutron/private: 
      neutron/floating: 
      fw-admin: "10.109.0.9"
      glance/api: "192.168.0.1"
      mgmt/vip: "192.168.0.1"
      murano/api: "192.168.0.1"
      nova/api: "192.168.0.1"
      horizon: "192.168.0.1"
      mgmt/memcache: "192.168.0.1"
      cinder/iscsi: "192.168.1.1"
      ceph/replication: "192.168.1.1"
    user_node_name: "Untitled (6a:e7)"
    node_roles: &id002
      
      - primary-mongo
    name: node-121
  nodes_hash: 
    - fqdn: node-121.test.domain.local
      internal_address: "192.168.0.1"
      internal_netmask: "255.255.255.0"
      name: node-121
      role: primary-mongo
      storage_address: "192.168.1.1"
      storage_netmask: "255.255.255.0"
      swift_zone: "121"
      uid: "121"
      user_node_name: "Untitled (18:c9)"
    - fqdn: node-124.test.domain.local
      internal_address: "192.168.0.2"
      internal_netmask: "255.255.255.0"
      name: node-124
      role: ceph-osd
      storage_address: "192.168.1.2"
      storage_netmask: "255.255.255.0"
      swift_zone: "124"
      uid: "124"
      user_node_name: "Untitled (6f:9d)"
    - fqdn: node-125.test.domain.local
      internal_address: "192.168.0.3"
      internal_netmask: "255.255.255.0"
      name: node-125
      public_address: "172.16.0.2"
      public_netmask: "255.255.255.0"
      role: primary-controller
      storage_address: "192.168.1.3"
      storage_netmask: "255.255.255.0"
      swift_zone: "125"
      uid: "125"
      user_node_name: "Untitled (34:45)"
    - fqdn: node-126.test.domain.local
      internal_address: "192.168.0.4"
      internal_netmask: "255.255.255.0"
      name: node-126
      role: ceph-osd
      storage_address: "192.168.1.4"
      storage_netmask: "255.255.255.0"
      swift_zone: "126"
      uid: "126"
      user_node_name: "Untitled (12:ea)"
    - fqdn: node-127.test.domain.local
      internal_address: "192.168.0.5"
      internal_netmask: "255.255.255.0"
      name: node-127
      role: compute
      storage_address: "192.168.1.5"
      storage_netmask: "255.255.255.0"
      swift_zone: "127"
      uid: "127"
      user_node_name: "Untitled (74:27)"
  nova_db_password: VXcP6cIR
  nova_hash: 
    db_password: VXcP6cIR
    state_path: /var/lib/nova
    user_password: fuhtZH6v
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
  primary_controller: false
  private_int: 
  queue_provider: rabbitmq
  rabbit_ha_queues: true
  rabbit_hash: 
    password: "1GXPbTgb"
    user: nova
  node_role: primary-mongo
  roles: *id002
  sahara_hash: 
    db_password: R68HpdNS
    enabled: false
    user_password: ts32qXcD
  sahara_roles: 
    - primary-controller
    - controller
  sql_connection: "mysql://nova:VXcP6cIR@192.168.0.7/nova?read_timeout = 6 0"
  storage_hash: 
    ephemeral_ceph: false
    images_ceph: true
    images_vcenter: false
    iser: false
    metadata: 
      label: Storage
      weight: 60
    objects_ceph: true
    osd_pool_size: "2"
    pg_num: 256
    volumes_ceph: true
    volumes_lvm: false
  swift_hash: 
    user_password: bpFT3TKn
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
  use_ceilometer: true
  use_monit: false
  use_neutron: true
  use_syslog: true
  vcenter_hash: {}
  verbose: true
  vlan_start: 
  management_vip: "192.168.0.7"
  database_vip: "192.168.0.7"
  service_endpoint: "192.168.0.7"
  public_vip: "172.16.0.3"
  management_vrouter_vip: "192.168.0.6"
  public_vrouter_vip: "172.16.0.3"
  memcache_roles: 
    - primary-controller
    - controller
  swift_master_role: primary-controller
  swift_nodes: 
    node-125: *id001
  swift_proxies: 
    node-125: *id001
  swift_proxy_caches: 
    node-125: *id001
  is_primary_swift_proxy: false
  nova_api_nodes: 
    node-125: *id001
',
  group   => 'root',
  mode    => '0644',
  owner   => 'root',
  path    => '/etc/hiera/globals.yaml',
}

stage { 'main':
  name => 'main',
}

