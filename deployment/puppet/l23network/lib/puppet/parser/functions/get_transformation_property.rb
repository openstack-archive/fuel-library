require 'puppetx/l23_network_scheme'

Puppet::Parser::Functions::newfunction(:get_transformation_property, :type => :rvalue, :doc => <<-EOS
    This function gets an endpoint properties from transformations --
    and returns information about the selected property

    ex: get_transformation_property('mtu','eth0')

    You can use following modes:
      mtu -- mtu value for the selected transformation.

    Returns NIL if a device is not found or mtu is not set

    EOS
  ) do |argv|
  if argv.size > 1
    mode = argv[0].to_s().upcase()
    argv.shift
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
  all_ifaces = ifaces.keys.map(&:to_s)
  devices = argv.flatten
  mtu = []

  rv = nil

  case mode
    when 'MTU'
      devices.each do |device|
        if all_ifaces.include? device and ifaces[device.to_sym][:mtu] != nil
          mtu.push(ifaces[device.to_sym][:mtu])
        else
          for i in 0..transforms.size-1 do
            transform = cfg[:transformations][i]
            if transform[:name] == device and transform[:mtu] != nil
              mtu.push(transform[:mtu])
            end
          end
        end
        if mtu.empty?
          Puppet::debug("get_transformation_property(...): MTU value is not set for interface '#{device}'.")
          rv = nil
        else
          rv = mtu.min
        end
      end
  end

  rv
end

# vim: set ts=2 sw=2 et :
