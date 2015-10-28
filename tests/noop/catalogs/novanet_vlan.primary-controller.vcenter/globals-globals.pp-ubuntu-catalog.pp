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
  amqp_hosts: "172.16.1.5:5673, 172.16.1.6:5673, 172.16.1.3:5673"
  amqp_port: "5673"
  apache_ports: 
    - "80"
    - "8888"
    - "5000"
    - "35357"
  base_mac: 
  base_syslog_hash: 
    syslog_port: "514"
    syslog_server: "10.109.0.2"
  ceph_monitor_nodes: 
    node-5: &id002
      
      user_node_name: "Untitled (56:9f)"
      uid: "5"
      fqdn: node-5.test.domain.local
      network_roles: 
        murano/api: "172.16.1.6"
        keystone/api: "172.16.1.6"
        mgmt/database: "172.16.1.6"
        sahara/api: "172.16.1.6"
        ceilometer/api: "172.16.1.6"
        ex: "172.16.0.6"
        ceph/public: "172.16.1.6"
        mgmt/messaging: "172.16.1.6"
        management: "172.16.1.6"
        swift/api: "172.16.1.6"
        storage: "192.168.1.4"
        mgmt/corosync: "172.16.1.6"
        cinder/api: "172.16.1.6"
        public/vip: "172.16.0.6"
        swift/replication: "192.168.1.4"
        ceph/radosgw: "172.16.0.6"
        admin/pxe: "10.109.0.7"
        mongo/db: "172.16.1.6"
        fw-admin: "10.109.0.7"
        glance/api: "172.16.1.6"
        mgmt/vip: "172.16.1.6"
        heat/api: "172.16.1.6"
        nova/api: "172.16.1.6"
        horizon: "172.16.1.6"
        mgmt/memcache: "172.16.1.6"
        cinder/iscsi: "192.168.1.4"
        ceph/replication: "192.168.1.4"
      swift_zone: "5"
      node_roles: 
        - controller
      name: node-5
    node-6: &id003
      
      user_node_name: "Untitled (8b:3c)"
      uid: "6"
      fqdn: node-6.test.domain.local
      network_roles: 
        murano/api: "172.16.1.3"
        keystone/api: "172.16.1.3"
        mgmt/database: "172.16.1.3"
        sahara/api: "172.16.1.3"
        ceilometer/api: "172.16.1.3"
        ex: "172.16.0.8"
        ceph/public: "172.16.1.3"
        mgmt/messaging: "172.16.1.3"
        management: "172.16.1.3"
        swift/api: "172.16.1.3"
        storage: "192.168.1.1"
        mgmt/corosync: "172.16.1.3"
        cinder/api: "172.16.1.3"
        public/vip: "172.16.0.8"
        swift/replication: "192.168.1.1"
        ceph/radosgw: "172.16.0.8"
        admin/pxe: "10.109.0.9"
        mongo/db: "172.16.1.3"
        fw-admin: "10.109.0.9"
        glance/api: "172.16.1.3"
        mgmt/vip: "172.16.1.3"
        heat/api: "172.16.1.3"
        nova/api: "172.16.1.3"
        horizon: "172.16.1.3"
        mgmt/memcache: "172.16.1.3"
        cinder/iscsi: "192.168.1.1"
        ceph/replication: "192.168.1.1"
      swift_zone: "6"
      node_roles: 
        - controller
      name: node-6
    node-3: &id001
      
      user_node_name: "Untitled (19:f0)"
      uid: "3"
      fqdn: node-3.test.domain.local
      network_roles: 
        murano/api: "172.16.1.5"
        keystone/api: "172.16.1.5"
        mgmt/database: "172.16.1.5"
        sahara/api: "172.16.1.5"
        ceilometer/api: "172.16.1.5"
        ex: "172.16.0.5"
        ceph/public: "172.16.1.5"
        mgmt/messaging: "172.16.1.5"
        management: "172.16.1.5"
        swift/api: "172.16.1.5"
        storage: "192.168.1.3"
        mgmt/corosync: "172.16.1.5"
        cinder/api: "172.16.1.5"
        public/vip: "172.16.0.5"
        swift/replication: "192.168.1.3"
        ceph/radosgw: "172.16.0.5"
        admin/pxe: "10.109.0.4"
        mongo/db: "172.16.1.5"
        fw-admin: "10.109.0.4"
        glance/api: "172.16.1.5"
        mgmt/vip: "172.16.1.5"
        heat/api: "172.16.1.5"
        nova/api: "172.16.1.5"
        horizon: "172.16.1.5"
        mgmt/memcache: "172.16.1.5"
        cinder/iscsi: "192.168.1.3"
        ceph/replication: "192.168.1.3"
      swift_zone: "3"
      node_roles: &id004
        
        - primary-controller
      name: node-3
  ceph_primary_monitor_node: 
    node-3: *id001
  ceph_rgw_nodes: 
    node-5: *id002
    node-6: *id003
    node-3: *id001
  ceilometer_hash: 
    db_password: r56XkOlD
    user_password: rM79wR8O
    metering_secret: RJzs6Oyi
    enabled: false
    event_time_to_live: "604800"
    metering_time_to_live: "604800"
    http_timeout: "600"
  ceilometer_nodes: 
    node-5: *id002
    node-6: *id003
    node-3: *id001
  cinder_hash: 
    instances: 
      - availability_zone_name: vcenter
        vc_password: "Qwer!1234"
        vc_host: "172.16.0.254"
        vc_user: "administrator@vsphere.local"
    user_password: isWEnzor
    fixed_key: "94fce8fa7b77d25911b2b311c965ac31014d6e39d3256998501f188ba805484d"
    db_password: Q4I97R7I
  cinder_nodes: 
    node-5: *id002
    node-6: *id003
    node-3: *id001
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
    node-5: *id002
    node-6: *id003
    node-3: *id001
  debug: false
  default_gateway: 
    - "172.16.0.1"
  deployment_mode: ha_compact
  dns_nameservers: 
    - "8.8.4.4"
    - "8.8.8.8"
  glance_backend: file
  glance_hash: 
    db_password: ICT8nfNP
    vc_user: ""
    vc_datastore: ""
    vc_host: ""
    vc_datacenter: ""
    vc_password: ""
    user_password: ONErUJGW
  glance_known_stores: false
  heat_hash: 
    db_password: vvKwC5nk
    user_password: Iu130Azv
    enabled: true
    auth_encryption_key: cce511b05ad01c693e2cc93d90a28fc2
    rabbit_password: fzGamkpk
  heat_roles: 
    - primary-controller
    - controller
  horizon_nodes: 
    node-5: *id002
    node-6: *id003
    node-3: *id001
  node_name: node-3
  idle_timeout: "3600"
  keystone_hash: 
    service_token_off: false
    db_password: RGAv0zS2
    admin_token: Ro9qKUKs
  manage_volumes: false
  management_network_range: "172.16.1.0/24"
  master_ip: "10.109.0.2"
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
    db_password: LpTa5Fel
    user_password: N0VcO3j3
    enabled: false
    rabbit_password: OWZM0x9z
  murano_roles: 
    - primary-controller
    - controller
  mysql_hash: 
    root_password: "4t67JmJk"
    wsrep_password: vugKPCKR
  network_config: 
    vlan_start: 103
  network_manager: nova.network.manager.VlanManager
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
        name: eth2.101
      - action: add-port
        bridge: br-storage
        name: eth4.102
    roles: 
      murano/api: br-mgmt
      keystone/api: br-mgmt
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
      fw-admin: br-fw-admin
      glance/api: br-mgmt
      heat/api: br-mgmt
      mgmt/vip: br-mgmt
      nova/api: br-mgmt
      horizon: br-mgmt
      novanetwork/vlan: eth1
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
      br-fw-admin: 
        IP: 
          - "10.109.0.4/24"
      br-storage: 
        IP: 
          - "192.168.1.3/24"
      br-mgmt: 
        IP: 
          - "172.16.1.5/24"
      eth1: 
        IP: none
      br-ex: 
        IP: 
          - "172.16.0.5/24"
        gateway: "172.16.0.1"
  network_size: 256
  neutron_config: {}
  neutron_db_password: 
  neutron_metadata_proxy_secret: 
  neutron_nodes: 
    node-5: *id002
    node-6: *id003
    node-3: *id001
  neutron_user_password: 
  node: *id001
  nodes_hash: 
    - user_node_name: "Untitled (19:f0)"
      uid: "3"
      public_address: "172.16.0.5"
      internal_netmask: "255.255.255.0"
      fqdn: node-3.test.domain.local
      role: primary-controller
      public_netmask: "255.255.255.0"
      internal_address: "172.16.1.5"
      storage_address: "192.168.1.3"
      swift_zone: "3"
      storage_netmask: "255.255.255.0"
      name: node-3
    - user_node_name: "Untitled (c8:39)"
      uid: "4"
      public_address: "172.16.0.7"
      internal_netmask: "255.255.255.0"
      fqdn: node-4.test.domain.local
      role: compute-vmware
      public_netmask: "255.255.255.0"
      internal_address: "172.16.1.7"
      storage_address: "192.168.1.5"
      swift_zone: "4"
      storage_netmask: "255.255.255.0"
      name: node-4
    - user_node_name: "Untitled (56:9f)"
      uid: "5"
      public_address: "172.16.0.6"
      internal_netmask: "255.255.255.0"
      fqdn: node-5.test.domain.local
      role: controller
      public_netmask: "255.255.255.0"
      internal_address: "172.16.1.6"
      storage_address: "192.168.1.4"
      swift_zone: "5"
      storage_netmask: "255.255.255.0"
      name: node-5
    - user_node_name: "Untitled (8b:3c)"
      uid: "6"
      public_address: "172.16.0.8"
      internal_netmask: "255.255.255.0"
      fqdn: node-6.test.domain.local
      role: controller
      public_netmask: "255.255.255.0"
      internal_address: "172.16.1.3"
      storage_address: "192.168.1.1"
      swift_zone: "6"
      storage_netmask: "255.255.255.0"
      name: node-6
    - user_node_name: "Untitled (c1:0b)"
      uid: "7"
      public_address: "172.16.0.4"
      internal_netmask: "255.255.255.0"
      fqdn: node-7.test.domain.local
      role: cinder-vmware
      public_netmask: "255.255.255.0"
      internal_address: "172.16.1.4"
      storage_address: "192.168.1.2"
      swift_zone: "7"
      storage_netmask: "255.255.255.0"
      name: node-7
  nova_db_password: owRNCV7f
  nova_hash: 
    db_password: owRNCV7f
    user_password: "77CHLe8y"
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
    vlan_start: 103
    network_manager: VlanManager
    num_networks: 1
    network_size: 256
  num_networks: 1
  openstack_version: "2015.1.0-7.0"
  primary_controller: true
  private_int: eth1
  queue_provider: rabbitmq
  rabbit_ha_queues: true
  rabbit_hash: 
    password: XrExAeLy
    user: nova
  node_role: primary-controller
  roles: *id004
  sahara_hash: 
    db_password: cvgVWOPT
    user_password: uG7mcKEZ
    enabled: false
  sahara_roles: 
    - primary-controller
    - controller
  sql_connection: "mysql://nova:owRNCV7f@172.16.1.2/nova?read_timeout = 6 0"
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
    user_password: JpzD0qLl
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
  use_neutron: false
  use_syslog: true
  vcenter_hash: 
    computes: 
      - datastore_regex: ".*"
        target_node: controllers
        service_name: cluster1
        availability_zone_name: vcenter
        vc_cluster: Cluster1
        vc_host: "172.16.0.254"
        vc_password: "Qwer!1234"
        vc_user: "administrator@vsphere.local"
      - datastore_regex: ".*"
        target_node: node-4
        service_name: cluster2
        availability_zone_name: vcenter
        vc_cluster: Cluster2
        vc_host: "172.16.0.254"
        vc_password: "Qwer!1234"
        vc_user: "administrator@vsphere.local"
    esxi_vlan_interface: vmnic0
  verbose: true
  vlan_start: 103
  management_vip: "172.16.1.2"
  database_vip: "172.16.1.2"
  service_endpoint: "172.16.1.2"
  public_vip: "172.16.0.3"
  management_vrouter_vip: "172.16.1.1"
  public_vrouter_vip: "172.16.0.2"
  memcache_roles: 
    - primary-controller
    - controller
  swift_master_role: primary-controller
  swift_nodes: 
    node-5: *id002
    node-6: *id003
    node-3: *id001
  swift_proxies: 
    node-5: *id002
    node-6: *id003
    node-3: *id001
  swift_proxy_caches: 
    node-5: *id002
    node-6: *id003
    node-3: *id001
  is_primary_swift_proxy: true
  nova_api_nodes: 
    node-5: *id002
    node-6: *id003
    node-3: *id001
',
  group   => 'root',
  mode    => '0644',
  owner   => 'root',
  path    => '/etc/hiera/globals.yaml',
}

stage { 'main':
  name => 'main',
}

