require File.join(File.dirname(__FILE__), '..','..','..','puppet/provider/ovs_base')
require 'puppetx/l23_dpdk_ports_mapping'

Puppet::Type.type(:l2_port).provide(:dpdkovs, :parent => Puppet::Provider::Ovs_base) do
  commands   :vsctl       => 'ovs-vsctl',
             :ethtool_cmd => 'ethtool'

  def self.get_dpdk_ports_mapping
    L23network.get_dpdk_ports_mapping
  end

  def self.get_instances(big_hash)
    dpdk_ports_mapping = self.get_dpdk_ports_mapping
    ports = big_hash.fetch(:port, {}).map do |port_name, port_info|
      [dpdk_ports_mapping[port_name], port_info] if dpdk_ports_mapping.include? port_name.to_s
    end
    Hash[ports]
  end

  def create
    debug("CREATE resource: #{@resource}")
    @old_property_hash = {}
    @property_flush = {}.merge! @resource

    return unless @resource[:bridge]

    dpdk_port = self.class.get_dpdk_ports_mapping[@resource[:interface]]
    raise Puppet::ExecutionFailure, "Can't add port '#{@resource[:interface]}'" unless dpdk_port

    begin
      vsctl(['--may-exist', 'add-port', @resource[:bridge], dpdk_port, '--', 'set', 'Interface', dpdk_port, 'type=dpdk'])
    rescue Puppet::ExecutionFailure => error
      raise Puppet::ExecutionFailure, "Can't add port '#{@resource[:interface]}'\n#{error}"
    end
  end

  def destroy
    debug("DESTROY resource: #{@resource}")
    dpdk_port = self.class.get_dpdk_ports_mapping[@resource[:interface]]
    raise Puppet::ExecutionFailure, "Can't delete port '#{@resource[:interface]}'" unless dpdk_port
    vsctl("del-port", dpdk_port)
  end

  def flush
    if ! @property_flush.empty?
      debug("FLUSH properties: #{@property_flush}")
      @property_hash = resource.to_hash
    end
  end
end
# vim: set ts=2 sw=2 et :