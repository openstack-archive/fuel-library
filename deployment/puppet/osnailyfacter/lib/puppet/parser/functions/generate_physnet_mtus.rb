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
    bridge_including_flow = {
        :'add-patch' => 'bridges',
        :'add-port' => 'bridge',
        :'add-bond' => 'bridge',
    }

   physnet_mtu_map = {}
    physnet_bridge_map.each do |net, br|
      mtu = nil
      if br['mtu']
        mtu = br['mtu']
      else
        br = br['name']
        bridge_including_flow.each do |x , v|
          bridge_included = network_scheme['transformations'].select { |a| a['action'] == x.to_s and a.has_key?(v) and (a[v] == br or a[v].include?(br)) }
          if bridge_included.empty?
            next
          elsif bridge_included.size >2
            raise("bridge #{br} can not be included into more then one element, elements: #{bridge_included}")
          else
            bridge_included = bridge_included[0]
            debug("Transformation #{bridge_included} has bridge #{br}")
          end
          if bridge_included['action'] == 'add-patch'
            debug("Bridge #{br} is in a patch #{bridge_included}!")
            br = bridge_included['bridges'].select{ |x| x!=br }[0]
            debug("Looking mtu for bridge #{br}")
	    next
          elsif bridge_included['mtu']
            mtu = bridge_included['mtu']
            debug("And has mtu: #{mtu}")
            break
          end
        end
        mtu = 1500 unless mtu
        physnet_mtu_map[net] = mtu
      end
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
