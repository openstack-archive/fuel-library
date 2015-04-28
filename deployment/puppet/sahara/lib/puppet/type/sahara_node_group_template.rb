Puppet::Type.newtype(:sahara_node_group_template) do

  ensurable

  newparam(:name) do
    desc 'The name of this node_group_template.'
    isnamevar
  end

  newproperty(:description) do
    desc 'The description of this node group template.'
    defaultto { @resource[:name] }
  end

  newproperty(:plugin_name) do
    desc 'The plugin name for current template'
    defaultto { fail 'plugin_name is required!' }
  end

  newproperty(:flavor_id) do
    desc 'The id of the flavor assigned to this node group template'
    defaultto { fail 'flavor_id is required!' }
  end

  newproperty(:node_processes, :array_matching => :all) do
    desc 'The array of node processes to run'
    defaultto { fail 'node_processes are required!' }
  end

  newproperty(:hadoop_version) do
    desc 'The Hadoop version of this template'
    defaultto { fail 'hadoop_version is required!' }
  end

  newproperty(:floating_ip_pool) do
    desc 'The id of floating ip pool'
  end

  newproperty(:auto_security_group) do
    desc 'Enable auto security group?'
    defaultto true
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
