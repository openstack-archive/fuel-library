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
      )
      should contain_exec("rebalance_#{ring}").with(
        'command' => "swift-ring-builder /etc/swift/#{ring}.builder rebalance",
      ).that_requires("Exec[hours_passed_#{ring}]")
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
