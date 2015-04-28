Puppet::Type.newtype(:sahara_cluster_template) do

  ensurable

  newparam(:name) do
    desc 'The name of this cluster_template.'
    isnamevar
  end

  newproperty(:description) do
    desc 'The description of this cluster template.'
    defaultto { @resource[:name] }
  end

  newproperty(:plugin_name) do
    desc 'The plugin name for current cluster template'
    defaultto { fail 'plugin_name is required!' }
  end

  newproperty(:node_groups, :array_matching => :all) do
    desc 'The array of node groups for cluster'
    defaultto { fail 'node groups is required!' }
  end

  newproperty(:hadoop_version) do
    desc 'The Hadoop version of this template'
    defaultto { fail 'hadoop_version is required!' }
  end

  newproperty(:neutron_management_network) do
    desc 'The id of private neutron network'
    defaultto { nil }
  end

  #########################################

  newparam(:auth_url) do
    desc 'The Keystone endpoint URL'
    defaultto 'http://localhost:35357/v2.0'
  end

  newparam(:auth_username) do
    desc 'Username with which to authenticate'
    defaultto 'admin'
  end

  newparam(:auth_password) do
    desc 'Password with which to authenticate'
    defaultto { fail 'auth_password is required!' }
  end

  newparam(:auth_tenant_name) do
    desc 'Tenant name with which to authenticate'
    defaultto 'admin'
  end

  newparam(:debug) do
    desc 'Enable library debug'
    defaultto false
  end

end
