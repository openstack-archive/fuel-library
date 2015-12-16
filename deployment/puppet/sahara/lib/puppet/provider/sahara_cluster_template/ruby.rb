require 'rubygems'
require 'openstack'
require File.join File.dirname(__FILE__), '../sahara_openstack.rb'

Puppet::Type.type(:sahara_cluster_template).provide(:ruby) do
  attr_accessor :property_hash

  def connection
    return @connection if @connection
    debug 'Call: connection'
    @connection = OpenStack::Connection.create({
                                                   :username => @resource[:auth_username],
                                                   :api_key => @resource[:auth_password],
                                                   :auth_method => 'password',
                                                   :auth_url => @resource[:auth_url],
                                                   :authtenant_name => @resource[:auth_tenant_name],
                                                   :service_type => 'data_processing',
                                                   :is_debug => @resource[:debug],
                                              })
  end

  def network_connection
    return @network_connection if @network_connection
    debug 'Call: network_connection'
    @network_connection = OpenStack::Connection.create({
                                                           :username => @resource[:auth_username],
                                                           :api_key => @resource[:auth_password],
                                                           :auth_method => 'password',
                                                           :auth_url => @resource[:auth_url],
                                                           :authtenant_name => @resource[:auth_tenant_name],
                                                           :service_type => 'network',
                                                           :is_debug => @resource[:debug],
                                                       })
  end

  def get_node_group_template_id(name, plugin_name)
    connection.list_node_group_templates.each do |template|
      return template[:id] if template[:name] == name and template[:plugin_name] == plugin_name
    end
    nil
  end

  def get_private_network_id(name)
    network_connection.list_networks.each do |network|
      return network.id if network.name == name
    end
    nil
  end

  def set_node_group_templates_ids
    @resource[:node_groups].each do |node_group|
      node_group_template_id = get_node_group_template_id node_group['name'], @resource[:plugin_name]
      fail "Could not get the node_group_template_id of the group '#{node_group['name']}'!" unless node_group_template_id
      debug "Set node_group_template_id of group #{node_group['name']} to: #{node_group_template_id}"
      node_group["node_group_template_id"] = node_group_template_id
    end
  end

  def set_private_network_id
    neutron_private_net_id = get_private_network_id @resource[:neutron_management_network]
    if neutron_private_net_id
      debug "Set neutron_management_network to: #{neutron_private_net_id}"
      @resource[:neutron_management_network] = neutron_private_net_id
    else
      warning "Neutron management network is not found"
      @resource[:neutron_management_network] = ''
    end
  end

  def extract
    debug 'Call: extract'
    cluster_templates = connection.list_cluster_templates
    cluster_template = cluster_templates.find do |template|
      template.name == @resource[:name]
    end
    if cluster_template
      @property_hash = {
          :ensure => :present,
          :id => cluster_template.id,
          :name => cluster_template.name,
          :description => cluster_template.description,
          :plugin_name => cluster_template.plugin_name,
          :hadoop_version => cluster_template.hadoop_version,
          :neutron_management_network => cluster_template.neutron_management_network,
          :node_groups => cluster_template.node_groups,
      }
    else
      @property_hash = {
          :ensure => :absent,
      }
    end
    debug "Existing state: #{@property_hash.inspect}"
    @property_hash
  end

  def present?
    @resource[:ensure] == :present
  end

  def neutron?
    @resource[:neutron]
  end

  def exists?
    debug 'Call: exists?'
    set_private_network_id if present? and neutron?
    set_node_group_templates_ids if present? and ! @resource[:neutron_management_network].empty?
    extract unless @property_hash.any?
    result = @property_hash[:ensure] == :present
    debug "Result: #{result}"
    result
  end

  def description
    @property_hash[:description]
  end

  def plugin_name
    @property_hash[:plugin_name]
  end

  def neutron_management_network
    @property_hash[:neutron_management_network]
  end

  def hadoop_version
    @property_hash[:hadoop_version]
  end

  def node_groups
    @property_hash[:node_groups]
  end

  def description=(value)
    @property_hash[:description] = value
  end

  def plugin_name=(value)
    @property_hash[:plugin_name] = value
  end

  def neutron_management_network=(value)
    @property_hash[:neutron_management_network] = value
  end

  def hadoop_version=(value)
    @property_hash[:hadoop_version] = value
  end

  def node_groups=(value)
    @property_hash[:node_groups] = value
  end

  def destroy
    debug 'Call: destroy'
    connection.delete_cluster_template @property_hash[:id] if @property_hash[:id]
  end

  def create
    debug 'Call: create'
    @property_hash = {
          :ensure => @resource[:ensure],
          :name => @resource[:name],
          :description => @resource[:description],
          :plugin_name => @resource[:plugin_name],
          :hadoop_version => @resource[:hadoop_version],
          :neutron_management_network => @resource[:neutron_management_network],
          :node_groups => @resource[:node_groups],
    }
  end

  def flush
    debug 'Call: flush'
    options = @property_hash.reject do |property, value|
      next true if [:id, :ensure].include? property
      if property == :neutron_management_network
        next true unless value
        next true unless neutron?
      end
    end
    options[:node_groups].each do |node_group|
      node_group['count'] = node_group['count'].to_i if node_group['count']
    end
    if present? && ! @property_hash[:neutron_management_network].empty?
      connection.create_cluster_template options unless @property_hash[:id]
    end
  end

end
