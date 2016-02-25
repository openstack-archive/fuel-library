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
    def insync?(is)
      return false unless is.count == should.count

      should_sort = should.sort_by { |n| n["name"] }
      is_sort = is.sort_by { |n| n["name"] }
      should_sort.zip(is_sort).each do |should_node,is_node|
        should_node.keys.each do |field|
          unless (is_node.has_key?(field) && should_node[field].to_s == is_node[field].to_s)
            return false
          end
        end
      end
      return true
    end
  end

  newproperty(:hadoop_version) do
    desc 'The Hadoop version of this template'
    defaultto { fail 'hadoop_version is required!' }
  end

  newproperty(:neutron_management_network) do
    desc 'The id of private neutron network'
    defaultto { 'admin_internal_net' }
  end

  #########################################

  newparam(:neutron) do
    desc 'Use "neutron_management_network" if neutron is enabled'
    defaultto { true }
  end

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
