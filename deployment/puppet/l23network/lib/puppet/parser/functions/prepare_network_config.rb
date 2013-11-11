begin
  require 'puppet/parser/functions/lib/l23network_scheme.rb'
rescue LoadError => e
  # puppet apply does not add module lib directories to the $LOAD_PATH (See
  # #4248). It should (in the future) but for the time being we need to be
  # defensive which is what this rescue block is doing.
  rb_file = File.join(File.dirname(__FILE__),'lib','l23network_scheme.rb')
  load rb_file if File.exists?(rb_file) or raise e
end
begin
  require 'puppet/parser/functions/lib/hash_tools.rb'
rescue LoadError => e
  # puppet apply does not add module lib directories to the $LOAD_PATH (See
  # #4248). It should (in the future) but for the time being we need to be
  # defensive which is what this rescue block is doing.
  rb_file = File.join(File.dirname(__FILE__),'lib','hash_tools.rb')
  load rb_file if File.exists?(rb_file) or raise e
end

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
    L23network::Scheme.set_config(lookupvar('l3_fqdn_hostname'), rv)
    return true
  end
end
# vim: set ts=2 sw=2 et :