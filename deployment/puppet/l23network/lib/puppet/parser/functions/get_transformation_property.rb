require 'puppetx/l23_network_scheme'

Puppet::Parser::Functions::newfunction(:get_transformation_property, :type => :rvalue, :doc => <<-EOS
    This function gets a physical device properties from transformations --
    and returns information about the selected property

    ex: get_transformation_property('bond0', 'mtu')

    You can use following modes:
      mtu -- mtu value for the selected device. nil if mtu is not set

    Returns NIL if a device is not found.

    EOS
  ) do |argv|
  if argv.size == 2
    mode = argv[1].to_s().upcase()
  else
      raise(Puppet::ParseError, "get_transformation_property(...): Wrong number of arguments.")
  end

  cfg = L23network::Scheme.get_config(lookupvar('l3_fqdn_hostname'))
  if cfg.nil?
    raise(Puppet::ParseError, "get_transformation_property(...): You must call prepare_network_config(...) first!")
  end

  if !cfg[:roles] || !cfg[:endpoints] || cfg[:roles].class.to_s() != "Hash" || cfg[:endpoints].class.to_s() != "Hash"
      raise(Puppet::ParseError, "get_transformation_property(...): Invalid cfg_hash format.")
  end

  transforms = cfg[:transformations]
  ifaces = cfg[:interfaces]
  iface = argv[0]

  rv = nil

  case mode
    when 'MTU'
      if iface.include? "bond"
        for i in 0..transforms.size do
          transform = cfg[:transformations][i]
	        t_type = transform.class.to_s
	        if t_type != "NilClass" and transform[:name] == iface
	          mtu = transform[:mtu]
	          break
	        end
        end
      else
        mtu = ifaces[iface.to_sym][:mtu]
      end
      if mtu.nil?
        Puppet::debug("get_transformation_property(...): MTU value is not set for interface '#{iface}'.")
      end
      rv = mtu
  end

  rv
end

# vim: set ts=2 sw=2 et :
