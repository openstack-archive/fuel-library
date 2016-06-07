require_relative '../../../puppetx/l23_network_scheme'
require_relative '../../../puppetx/l23_hash_tools'

module Puppet::Parser::Functions
  newfunction(:prepare_network_config, :doc => <<-EOS
    This function get Hash, and prepare it for using for network configuration.

    You must call this function as early as possible. It do nothing, only stored protected
    sanitized network config for usind later.
    EOS
  ) do |argv|
    if argv.size != 1
      raise(Puppet::ParseError, "prepare_network_config(hash): Wrong number of arguments.")
    end
    cfg_hash = argv[0]
    Puppet::Parser::Functions.autoloader.loadall
    rv = L23network.sanitize_bool_in_hash(L23network.sanitize_keys_in_hash(cfg_hash))
    rv = L23network.override_transformations(rv)
    rv = L23network.remove_empty_members(rv)
    L23network::Scheme.set_config(lookupvar('l3_fqdn_hostname'), rv)
    return true
  end
end
# vim: set ts=2 sw=2 et :