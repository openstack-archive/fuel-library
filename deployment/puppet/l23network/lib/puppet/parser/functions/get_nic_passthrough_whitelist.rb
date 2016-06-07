require_relative '../../../puppetx/l23_network_scheme'

Puppet::Parser::Functions::newfunction(:get_nic_passthrough_whitelist, :type => :rvalue, :arity => 1, :doc => <<-EOS
    This function gets pci_passthrough_whitelist mapping from transformations
    Returns NIL if no transformations with this provider found or list
    ex: pci_passthrough_whitelist('sriov')
    EOS
  ) do |argv|
  provider = argv[0].to_s.upcase

  cfg = L23network::Scheme.get_config(lookupvar('l3_fqdn_hostname'))
  transformations = cfg[:transformations]
  rv = []

  transformations.each do |transform|
    if transform[:provider].to_s.upcase == provider and\
       transform[:action] == "add-port" and\
       transform[:vendor_specific][:physnet]
      rv.push({"devname" => transform[:name], "physical_network" => transform[:vendor_specific][:physnet]})
    end
  end

  rv unless rv.empty?
end

# vim: set ts=2 sw=2 et :
