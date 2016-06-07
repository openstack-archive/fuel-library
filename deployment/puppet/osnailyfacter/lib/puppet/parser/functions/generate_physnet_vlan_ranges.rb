Puppet::Parser::Functions::newfunction(:generate_physnet_vlan_ranges, :type => :rvalue, :doc => <<-EOS
This function gets neutron_config, network_scheme, flags and formats physnet to vlan ranges according to flags.
EOS
) do |args|

   raise ArgumentError, ("generate_physnet_vlan_ranges(): wrong number of arguments (#{args.length}; must be 3)") if args.length < 3
   raise ArgumentError, ("generate_physnet_vlan_ranges(): wrong number of arguments (#{args.length}; must be 3)") if args.length > 3
   args.each do | arg |
     raise ArgumentError, "generate_physnet_vlan_ranges(): #{arg} is not hash!" unless arg.is_a?(Hash)
   end

   neutron_config = args[0]
   network_scheme = args[1]
   flags = args[2]
   #flags = { do_floating => true, do_tenant   => true, do_provider => false }

   debug "Collecting phys_nets and bridges"
   physnet_bridge_map = {}
    neutron_config['L2']['phys_nets'].each do |k,v|
      next unless v['bridge']
      bridge = v['bridge']
      physnet_bridge_map[k] = v['vlan_range'] unless network_scheme['transformations'].select{ |x| x['name'] == bridge }.empty?
    end

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

    debug("Formatng the output")
    result = []
    physnet_bridge_map.each do |net, vr|
      record = ''
      record += ":#{vr}" if vr and not vr == :undef
      result << "#{net}"+ record
    end
    debug("Format is done, value is: #{result}")
    result
end
