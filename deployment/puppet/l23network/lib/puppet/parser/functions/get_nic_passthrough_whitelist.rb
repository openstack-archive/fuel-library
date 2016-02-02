require 'puppetx/l23_network_scheme'

Puppet::Parser::Functions::newfunction(:get_nic_passthrough_whitelist, :type => :rvalue, :doc => <<-EOS
    This function gets pci_passthrough_whitelist mapping from transformations

    ex: get_transformation_property('sriov')

    Returns NIL if no transformations with this provider found or list

    EOS
  ) do |argv|
  if argv.size == 1
    provider = argv[0].to_s().upcase()
    argv.shift
  else
      raise(Puppet::ParseError, "get_transformation_property(...): Wrong number of arguments.")
  end

  cfg = L23network::Scheme.get_config(lookupvar('l3_fqdn_hostname'))
  transformations = cfg[:transformations]
  rv = []

  for i in 0..transformations.size-1 do
    transform = cfg[:transformations][i]
    if transform[:provider].to_s().upcase() == provider and transform[:action] == "add-port"
      rv.push({"devname" => transform[:name], "physical_network" => transform[:vendor_specific][:physnet]})
    end
  end

  return rv if not rv.empty?
  return nil
end

# vim: set ts=2 sw=2 et :
