require 'rubygems'
require 'openstack'
require File.join File.dirname(__FILE__), '../sahara_openstack.rb'

Puppet::Type.type(:sahara_node_group_template).provide(:ruby) do
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

  def compute_connection
    return @compute_connection if @compute_connection
    debug 'Call: compute_connection'
    @compute_connection = OpenStack::Connection.create({
                                                           :username => @resource[:auth_username],
                                                           :api_key => @resource[:auth_password],
                                                           :auth_method => 'password',
                                                           :auth_url => @resource[:auth_url],
                                                           :authtenant_name => @resource[:auth_tenant_name],
                                                           :service_type => 'compute',
                                                           :is_debug => @resource[:debug],
                                                       })
  end

  def get_external_network_id(name=nil)
    return 'nova' unless neutron?
    network_connection.list_routers.each do |router|
      next unless router.external_gateway_info.is_a? Hash
      if router.external_gateway_info['network_id']
        return router.external_gateway_info['network_id'] if name.nil? or router.name == name
      end
    end
    nil
  end

  def get_nova_flavor_id(name)
    compute_connection.list_flavors.each do |flavor|
      return flavor[:id] if flavor[:name] == name
    end
    nil
  end

  def set_floating_ip_pool_id
    return if @resource[:floating_ip_pool] and @resource[:floating_ip_pool].length == 36 and @resource[:floating_ip_pool] =~ /^[a-z0-9\-]+$/
    external_network_id = get_external_network_id @resource[:floating_ip_pool]
    if external_network_id
      debug "Set floating_ip_pool to: #{external_network_id}"
      @resource[:floating_ip_pool] = external_network_id
    else
      warning "Floating ip pool is not found"
      @resource[:floating_ip_pool] = ''
    end
  end

  def set_flavor_id
    return if resource[:flavor_id].to_i.to_s == resource[:flavor_id]
    flavor_id = get_nova_flavor_id resource[:flavor_id]
    if flavor_id
      debug "Set flavor_id to: #{flavor_id}"
      resource[:flavor_id] = flavor_id
    end
  end

  def extract
    debug 'Call: extract'
    node_group_templates = connection.list_node_group_templates
    node_group_template = node_group_templates.find do |template|
      template.name == @resource[:name]
    end
    if node_group_template
      @property_hash = {
          :ensure => :present,
          :id => node_group_template.id,
          :name => node_group_template.name,
          :description => node_group_template.description,
          :plugin_name => node_group_template.plugin_name,
          :flavor_id => node_group_template.flavor_id,
          :node_processes => node_group_template.node_processes,
          :hadoop_version => node_group_template.hadoop_version,
          :floating_ip_pool => node_group_template.floating_ip_pool,
          :auto_security_group => node_group_template.auto_security_group,
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
    set_floating_ip_pool_id if present?
    set_flavor_id if present?
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

  def flavor_id
    @property_hash[:flavor_id]
  end

  def node_processes
    @property_hash[:node_processes]
  end

  def hadoop_version
    @property_hash[:hadoop_version]
  end

  def floating_ip_pool
    @property_hash[:floating_ip_pool]
  end

  def auto_security_group
    @property_hash[:auto_security_group]
  end

  def description=(value)
    @property_hash[:description] = value
  end

  def plugin_name=(value)
    @property_hash[:plugin_name] = value
  end

  def flavor_id=(value)
    @property_hash[:flavor_id] = value
  end

  def node_processes=(value)
    @property_hash[:node_processes] = value
  end

  def hadoop_version=(value)
    @property_hash[:hadoop_version] = value
  end

  def floating_ip_pool=(value)
    @property_hash[:floating_ip_pool] = value
  end

  def auto_security_group=(value)
    @property_hash[:auto_security_group] = value
  end

  def destroy
    debug 'Call: destroy'
    connection.delete_node_group_template @property_hash[:id] if @property_hash[:id]
  end

  def create
    debug 'Call: create'
    @property_hash = {
        :ensure => @resource[:ensure],
        :name => @resource[:name],
        :description => @resource[:description],
        :plugin_name => @resource[:plugin_name],
        :flavor_id => @resource[:flavor_id],
        :node_processes => @resource[:node_processes],
        :hadoop_version => @resource[:hadoop_version],
        :floating_ip_pool => @resource[:floating_ip_pool],
        :auto_security_group => @resource[:auto_security_group],
    }
  end

  def flush
    debug 'Call: flush'
    options = @property_hash.reject { |k, v| [:id, :ensure].include? k }
    if present? && ! @property_hash[:floating_ip_pool].empty?
      connection.create_node_group_template options unless @property_hash[:id]
    end
  end

end
