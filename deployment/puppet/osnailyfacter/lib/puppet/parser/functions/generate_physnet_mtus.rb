DEFAULT_MTU ||= 1500

def get_mtu_for_bridge(br_name, network_scheme, inspected_bridges)
  mtu = nil
  # in this chain patch should be last, because ports and bonds has highest priority
  {'add-port' => 'bridge' , 'add-bond' => 'bridge', 'add-patch' => 'bridges'}.each do |x , v|
    transf = network_scheme['transformations'].select do |trans|
      trans['action']==x and trans.has_key?(v) and (trans[v]==br_name or trans[v].include?(br_name))
    end
    if transf.empty?
      next
    elsif transf.size >2
      raise("bridge #{br_name} can not be included into more then one element, elements: #{transf}")
    else
      transf = transf[0]
      debug("Transformation #{transf} has bridge #{br_name}")
    end
    if transf['action'] == 'add-patch'
      debug("Bridge #{br_name} is in a patch #{transf}!")
      next_br_name = transf['bridges'].select{ |x| x!=br_name }[0]
      if ! inspected_bridges.include?(br_name)
        debug("Looking mtu for bridge #{next_br_name}")
        inspected_bridges << br_name
        mtu = get_mtu_for_bridge(next_br_name, network_scheme, inspected_bridges)
      else
        next
      end
    elsif !transf['mtu'].nil?
      # this section into elsif, because patch MTU shouldn't affect result (MTU 65000 for example)
      mtu = transf['mtu']
    elsif transf['action']=='add-port' and !network_scheme['interfaces'].fetch(transf['name'],{}).fetch('mtu',nil).nil?
      mtu = network_scheme['interfaces'][transf['name']]['mtu']
    end
    if !mtu.nil?
      debug("And has mtu: #{mtu}")
      break
    end
  end
  mtu ||= DEFAULT_MTU
  return mtu
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
      mtu = nil
      if br['mtu']
        mtu = br['mtu']
      else
        mtu = get_mtu_for_bridge(br['name'], network_scheme, [])
      end
      physnet_mtu_map[net] = mtu
    end

    debug("Formatng the output")
    result = []
    return result if physnet_mtu_map.empty?
    physnet_mtu_map.each do |net, mtu|
      record = mtu ?  ":#{mtu}" : ''
      result << "#{net}"+ record
    end
    debug("Format is done, value is: #{result}")
    result
end
