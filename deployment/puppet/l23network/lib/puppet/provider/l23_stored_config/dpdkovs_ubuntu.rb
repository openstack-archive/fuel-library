require_relative '../l23_stored_config_ubuntu'

Puppet::Type.type(:l23_stored_config).provide(:dpdkovs_ubuntu, :parent => Puppet::Provider::L23_stored_config_ubuntu) do

  include PuppetX::FileMapper

  confine    :l23_os => :ubuntu

  has_feature :provider_options

  self.unlink_empty_files = true

  def self.get_dpdk_ports_mapping
    L23network.get_dpdk_ports_mapping
  end

  def self.check_if_provider(if_data)
    if if_data[:if_type] =~ /dpdkovsport/
        if_data[:if_type] = "ethernet"
        if_data[:if_provider] = :dpdkovs
        true
    elsif if_data[:if_type] =~ /dpdkovsbond/
        if_data[:if_type] = "bond"
        if_data[:if_provider] = :dpdkovs
        true
    elsif if_data[:if_type] == :bridge
        if_data[:if_provider] = :dpdkovs
        true
    else
        if_data[:if_provider] = nil
        false
    end
  end

  def self.property_mappings
    super.merge(
      :if_type               => 'ovs_type',
      :bridge                => 'ovs_bridge',
      :bridge_ports          => 'ovs_ports',
      :dpdk_port             => 'dpdk_port',
      :bond_slaves           => 'ovs_bonds',
      :bond_mode             => 'ovs_options',
      :bond_miimon           => 'ovs_options',
      :bond_use_carrier      => 'ovs_options',
      :bond_lacp_rate        => 'ovs_options',
      :bond_lacp             => 'ovs_options',
      :bond_xmit_hash_policy => '', # unused
      :bond_ad_select        => '',
      :bond_updelay          => 'ovs_options',
      :bond_downdelay        => 'ovs_options',
      :multiq_threads        => 'multiq_threads',
    )
  end

  def self.oneline_properties
    {
      :bond_mode => {
          :field    => 'bond_mode',
          :store_to => 'ovs_options'
      },
      :bond_updelay => {
          :field    => 'bond_updelay',
          :store_to => 'ovs_options'
      },
      :bond_downdelay => {
          :field    => 'bond_downdelay',
          :store_to => 'ovs_options'
      },
      :bond_lacp => {
          :field    => 'lacp',
          :store_to => 'ovs_options'
      },
      :bond_lacp_rate  => {
          :field    => 'other_config:lacp-time',
          :store_to => 'ovs_options'
      },
      :bond_miimon  => {
          :field    => 'other_config:bond-miimon-interval',
          :store_to => 'ovs_options'
      },
      :bond_use_carrier  => {
          :field    => 'other_config:bond-detect-mode',
          :store_to => 'ovs_options'
      },
    }
  end
  def oneline_properties
    self.class.collected_properties
  end

  def self.collected_properties
    super.merge(
      :datapath_type  => {
        :detect_re    => /(ovs_)?extra\s+set\s+Bridge\s+([a-z][0-9a-z\-]*[0-9a-z])\s+datapath_type=([a-z]+)/,
        :detect_shift => 3,
      },
    )
  end

  def self.iface_file_header(provider)
    header = []
    props  = {}

    header << self.puppet_header
    bridge = provider.bridge[0]

    if provider.if_type == :bridge
      header << "auto #{provider.name}" if provider.onboot
      header << "allow-ovs #{provider.name}"
      props[:bridge]   = nil
    else
      header << "allow-#{bridge} #{provider.name}"
      props[:bridge] = bridge
    end

    header << "iface #{provider.name} inet #{provider.method}"

    [header, props]
  end

  def dpdk_port
    dpdk_ports = self.class.get_dpdk_ports_mapping
    dpdk_port = dpdk_ports[self.name]
  end

  def multiq_threads
    if self.if_type == 'bond'
      cfg = L23network::Scheme.get_config(Facter.value(:l3_fqdn_hostname))
      multiq_threads =  self.bond_slaves.map { |iface| cfg[:interfaces][iface.to_sym][:vendor_specific][:max_queues]}.min
    else
      multiq_threads = self.vendor_specific['max_queues']
    end
  end

  def self.mangle__bond_slaves(val)
    ports_dpdk_mapping = self.get_dpdk_ports_mapping.invert
    val.split(/[\s,]+/).map {|i| ports_dpdk_mapping[i]}.sort
  end

  def self.unmangle__bond_slaves(provider, val)
    dpdk_ports_mapping = self.get_dpdk_ports_mapping
    if val.size < 1 or [:absent, :undef].include? Array(val)[0].to_sym
      nil
    else
      val.map {|i| dpdk_ports_mapping[i]}.sort.join(' ')
    end
  end

  def self.unmangle__bond_use_carrier(provider, data)
    values = [ 'miimon', 'carrier' ]
    rv = values[data.to_i] if data.to_i <= values.size
    rv ||= nil
  end

  def self.unmangle__if_type(provider, val)
    case val
    when :ethernet; 'DPDKOVSPort'
    when :bond; 'DPDKOVSBond'
    else "OVS#{val.to_s.capitalize}"
    end
  end

  def self.mangle__if_type(val)
    val.sub(/^OVS/, '').downcase.to_sym
  end

  def self.unmangle__datapath_type(provider, val)
    ["ovs_extra set Bridge #{provider.name} datapath_type=#{provider.datapath_type}"] \
    if provider.if_type == :bridge && provider.datapath_type
  end

  def self.mangle__datapath_type(data)
    data.join
  end

end

# vim: set ts=2 sw=2 et :
