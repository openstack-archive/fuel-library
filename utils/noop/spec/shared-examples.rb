# Shared functions
def filter_nodes(hash, name, value)
  hash.select do |it|
    it[name] == value
  end
end

def nodes_to_hash(hash, name, value)
  result = {}
  hash.each do |element|
    result[element[name]] = element[value]
  end
  return result
end

def ipsort (ips)
  require 'rubygems'
  require 'ipaddr'
  sorted_ips = ips.sort { |a,b| IPAddr.new( a ) <=> IPAddr.new( b ) }
  return sorted_ips
end


# Shared examples
shared_examples 'controller with keystone' do | admin_token, memcache_servers |
  it 'should declare keystone class with admin_token' do
    should contain_class('keystone').with(
      'admin_token' => admin_token,
    )
  end

  it 'should configure memcache_pool keystone cache backend' do
    should contain_keystone_config('token/caching').with(:value => 'false')
    should contain_keystone_config('cache/enabled').with(:value => 'true')
    should contain_keystone_config('cache/backend').with(:value => 'keystone.cache.memcache_pool')
    should contain_keystone_config('cache/memcache_servers').with(:value => memcache_servers)
    should contain_keystone_config('cache/memcache_dead_retry').with(:value => '300')
    should contain_keystone_config('cache/memcache_socket_timeout').with(:value => '3')
    should contain_keystone_config('cache/memcache_pool_maxsize').with(:value => '100')
    should contain_keystone_config('cache/memcache_pool_unused_timeout').with(:value => '60')
  end
end

shared_examples 'controller with horizon' do | nova_quota, api_bind_address |
  it 'should declare openstack::horizon class' do
    should contain_class('openstack::horizon').with(
      'nova_quota'   => nova_quota,
      'bind_address' => api_bind_address,
    )
  end
end

shared_examples 'controller with ceilometer' do | amqp_user, amqp_password, use_neutron, rabbit_ha_queues |
  it 'should declare openstack::ceilometer class' do
    should contain_class('openstack::ceilometer').with(
      'amqp_user'        => amqp_user,
      'amqp_password'    => amqp_password,
      'rabbit_ha_queues' => rabbit_ha_queues,
      'on_controller'    => 'true',
    )
  end
  if use_neutron == 'true'
    it 'should configure notification_driver for neutron' do
      should contain_neutron_config('DEFAULT/notification_driver').with(
        'value' => 'messaging',
      )
    end
  end
end

shared_examples 'controller without neutron' do
  it 'should declare openstack::network with neutron disabled' do
    should contain_class('openstack::network').with(
      'neutron_server' => 'false',
    )
  end
end

shared_examples 'controller with neutron' do
  it 'should declare openstack::network with neutron enabled' do
    should contain_class('openstack::network').with(
      'neutron_server' => 'true',
    )
  end
end

shared_examples 'node with sahara' do | sahara_db_password, sahara_keystone_password, use_neutron, rabbit_ha_queues |
  it 'should declare sahara class correctly' do
    should contain_class('sahara').with(
      'sahara_db_password'       => sahara_db_password,
      'sahara_keystone_password' => sahara_keystone_password,
      'use_neutron'              => use_neutron,
      'rpc_backend'              => 'rabbit',
      'rabbit_ha_queues'         => rabbit_ha_queues,
    )
  end
end

shared_examples 'node with murano' do | murano_os_rabbit_userid, murano_os_rabbit_passwd, use_neutron |
  it 'should declare murano class correctly and after openstack::heat' do
    should contain_class('murano').with(
      'murano_os_rabbit_userid' => murano_os_rabbit_userid,
      'murano_os_rabbit_passwd' => murano_os_rabbit_passwd,
      'use_neutron'             => use_neutron,
    ).that_requires('Class[openstack::heat]')
  end
end

shared_examples 'primary controller with swift' do
  ['account', 'object', 'container'].each do | ring |
    it "should run pretend_min_part_hours_passed before rabalancing swift #{ring} ring" do
      should contain_exec("hours_passed_#{ring}").with(
        'command' => "swift-ring-builder /etc/swift/#{ring}.builder pretend_min_part_hours_passed",
        'user'    => 'swift',
      )
      should contain_exec("rebalance_#{ring}").with(
        'command' => "swift-ring-builder /etc/swift/#{ring}.builder rebalance",
        'user'    => 'swift',
      ).that_requires("Exec[hours_passed_#{ring}]")
      should contain_exec("create_#{ring}").with(
        'user'    => 'swift',
      )
    end
  end
end

shared_examples 'ha controller with swift' do
  it 'should create /etc/swift/backups directory with correct ownership' do
    should contain_file('/etc/swift/backups').with(
      'ensure' => 'directory',
      'owner'  => 'swift',
      'group'  => 'swift',
    )
  end
end

shared_examples 'compute node' do | use_neutron, internal_address |
  it 'should configure listen_tls, listen_tcp and auth_tcp in libvirtd.conf' do
    should contain_augeas('libvirt-conf').with(
      'context' => '/files/etc/libvirt/libvirtd.conf',
      'changes' => [
        'set listen_tls 0',
        'set listen_tcp 1',
        'set auth_tcp none',
      ],
    )
  end
  it 'should contain needed nova_config options' do
    should contain_nova_config('libvirt/live_migration_flag').with(
      'value' => 'VIR_MIGRATE_UNDEFINE_SOURCE,VIR_MIGRATE_PEER2PEER,VIR_MIGRATE_LIVE,VIR_MIGRATE_PERSIST_DEST',
    )
    should contain_nova_config('DEFAULT/cinder_catalog_info').with(
      'value' => 'volume:cinder:internalURL'
    )
    should contain_nova_config('DEFAULT/use_syslog_rfc_format').with(
      'value' => 'true',
    )

    should contain_nova_config('DEFAULT/connection_type').with(
      'value' => 'libvirt',
    )
    should contain_nova_config('DEFAULT/allow_resize_to_same_host').with(
      'value' => 'true',
    )
  end

  if use_neutron
    it 'should create /etc/libvirt/qemu.conf file that notifies libvirt service' do
      should contain_file('/etc/libvirt/qemu.conf').with(
        'ensure' => 'present',
        'source' => 'puppet:///modules/nova/libvirt_qemu.conf',
      ).that_notifies('Service[libvirt]')
    end
    it 'should configure linuxnet_interface_driver and linuxnet_ovs_integration_bridge' do
      should contain_nova_config('DEFAULT/linuxnet_interface_driver').with(
        'value' => 'nova.network.linux_net.LinuxOVSInterfaceDriver',
      )
      should contain_nova_config('DEFAULT/linuxnet_ovs_integration_bridge').with(
        'value' => 'br-int',
      )
    end
    it 'should configure net.bridge.bridge* keys that come before libvirt service' do
      should contain_augeas('sysctl-net.bridge.bridge-nf-call-arptables').with(
        'context' => '/files/etc/sysctl.conf',
        'changes' => "set net.bridge.bridge-nf-call-arptables '1'",
      ).that_comes_before('Service[libvirt]')
      should contain_augeas('sysctl-net.bridge.bridge-nf-call-iptables').with(
        'context' => '/files/etc/sysctl.conf',
        'changes' => "set net.bridge.bridge-nf-call-iptables '1'",
      ).that_comes_before('Service[libvirt]')
      should contain_augeas('sysctl-net.bridge.bridge-nf-call-ip6tables').with(
        'context' => '/files/etc/sysctl.conf',
        'changes' => "set net.bridge.bridge-nf-call-ip6tables '1'",
      ).that_comes_before('Service[libvirt]')
    end
  else
    it 'should configure multi_host, send_arp_for_ha, metadata_host in nova.conf for nova-network' do
      should contain_nova_config('DEFAULT/multi_host').with(
        'value' => 'True',
      )
      should contain_nova_config('DEFAULT/send_arp_for_ha').with(
        'value' => 'True',
      )
      should contain_nova_config('DEFAULT/metadata_host').with(
        'value' => internal_address,
      )
    end
  end

end
