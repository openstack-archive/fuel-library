DEFAULT_MTU ||= 1500

class MinMTU
  def value=(new_mtu)
    return if new_mtu.nil? || new_mtu >= 65000

    @min_mtu = new_mtu if @min_mtu.nil? || @min_mtu > new_mtu
  end

  def value
    @min_mtu
  end
end

def get_mtu_for_bridge(br_name, network_scheme, inspected_bridges, min_mtu)
  {'add-port' => 'bridge' , 'add-bond' => 'bridge', 'add-patch' => 'bridges'}
    .each do |action, has_bridge|
      transfs = network_scheme['transformations'].select do |trans|
        trans['action'] == action &&
        trans.has_key?(has_bridge) &&
        (trans[has_bridge] == br_name || trans[has_bridge].include?(br_name))
      end

      transfs.each do |transf|
        min_mtu.value = transf['mtu'] if transf['mtu']

        if transf['action'] == 'add-patch'
          inspected_bridges << br_name
          (transf['bridges'] - inspected_bridges).each do |next_br_name|
            get_mtu_for_bridge(next_br_name, network_scheme, inspected_bridges, min_mtu)
          end
        elsif transf['action'] == 'add-port'
          min_mtu.value = network_scheme['interfaces'].fetch(transf['name'], {})['mtu']
        end
      end
    end

  min_mtu.value || DEFAULT_MTU
end

Puppet::Parser::Functions::newfunction(:generate_physnet_mtus, :type => :rvalue, :doc => <<-EOS
This function gets neutron_config, network_scheme, flags and formats physnet to vlan ranges according to flags.
EOS
) do |args|

   raise ArgumentError, ("generate_physnet_mtus(): wrong number of arguments (#{args.length}; must be 3)") if args.length != 3
   args.each do | arg |
     raise ArgumentError, "generate_physnet_mtus(): #{arg} is not hash!" if !arg.is_a?(Hash)
   end

   neutron_config, network_scheme, flags = *args

   #flags = { do_floating => true, do_tenant   => true, do_provider => false }

   debug "Collecting phys_nets and bridges"
   physnet_bridge_map = {}
    neutron_config['L2']['phys_nets'].each do |k,v|
      next unless v['bridge']
      bridge = v['bridge']
      trans = network_scheme['transformations'].select{ |x| x['name'] == bridge }
      physnet_bridge_map[k] = trans[0] unless trans.empty?
    end

    debug("Physnet to bridge map: #{physnet_bridge_map}")

    unless flags['do_floating']
      debug("Perform floating networks")
      physnet_bridge_map.each do | net, br |
        physnet_bridge_map.delete(net) unless neutron_config['predefined_networks'].select{ |pnet, value| value['L2']['physnet'] == net and value['L2']['router_ext'] }.empty?
      end
    end

    unless flags['do_tenant']
      debug("Perform tenant networks")
      physnet_bridge_map.each do | net, br |
        physnet_bridge_map.delete(net) unless neutron_config['predefined_networks'].select{ |pnet, value| value['L2']['physnet'] == net and !value['L2']['router_ext'] }.empty?
      end
    end

    return [] if physnet_bridge_map.empty?

    # Looking for MTUs
    physnet_mtu_map = {}
    physnet_bridge_map.each do |net, br|
      physnet_mtu_map[net] = br['mtu'] ? br['mtu'] : get_mtu_for_bridge(br['name'], network_scheme, [], MinMTU.new)
    end

    result = []
    return result if physnet_mtu_map.empty?
    physnet_mtu_map.each do |net, mtu|
      record = mtu ?  ":#{mtu}" : ''
      result << "#{net}"+ record
    end
    debug("Format is done, value is: #{result}")
    result
end
