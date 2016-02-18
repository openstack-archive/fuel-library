require File.join(File.dirname(__FILE__), '..','..','..','puppet/provider/ovs_base')
require 'puppetx/l23_dpdk_ports_mapping'

Puppet::Type.type(:l2_port).provide(:dpdkovs, :parent => Puppet::Provider::Ovs_base) do
  commands   :vsctl       => 'ovs-vsctl',
             :ethtool_cmd => 'ethtool'

  def self.get_dpdk_ports_mapping
    L23network.get_dpdk_ports_mapping
  end

  def self.get_instances(big_hash)
    dpdk_ports_mapping = get_dpdk_ports_mapping()
    ports = big_hash.fetch(:port, {}).map do |p_name, p_info|
      dpdk_info = dpdk_ports_mapping[p_name.to_s]
      p_info.merge!(dpdk_info) if dpdk_info
      [p_info[:interface] || p_name, p_info]
    end
    Hash[ports].select {|k,v| v[:type].to_s == 'dpdk'}
  end

  def create
    debug("CREATE resource: #{@resource}")
    @old_property_hash = {}
    @property_flush = {}.merge! @resource

    ports = self.class.get_dpdk_ports_mapping()
    dpdk_prop = ports.map { |i,p| p if p[:interface] == @resource[:interface]}.compact[0]
    raise Puppet::ExecutionFailure, "Can't add port '#{@resource[:interface]}'\n#{error}" unless dpdk_prop
    @property_flush.merge! dpdk_prop

    cmd = ['--may-exist', 'add-port', @resource[:bridge], @property_flush[:vendor_specific]['dpdk_port']]
    tt = "type=" + @property_flush[:type].to_s
    cmd += ['--', "set", "Interface", @property_flush[:vendor_specific]['dpdk_port'], tt] if tt

    begin
      vsctl(cmd)
    rescue Puppet::ExecutionFailure => error
      raise Puppet::ExecutionFailure, "Can't add port '#{@resource[:interface]}'\n#{error}"
    end
  end

  def destroy
    debug("DESTROY resource: #{@resource}")
    vsctl("del-port", @resource[:bridge], @resource[:vendor_specific]['dpdk_port'])
  end

  def flush
    if ! @property_flush.empty?
      debug("FLUSH properties: #{@property_flush}")
      @property_hash = resource.to_hash
    end
  end
end
# vim: set ts=2 sw=2 et :