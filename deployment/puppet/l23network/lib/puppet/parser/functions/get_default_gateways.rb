require 'ipaddr'
begin
  require 'puppet/parser/functions/lib/prepare_cidr.rb'
rescue LoadError => e
  # puppet apply does not add module lib directories to the $LOAD_PATH (See
  # #4248). It should (in the future) but for the time being we need to be
  # defensive which is what this rescue block is doing.
  rb_file = File.join(File.dirname(__FILE__),'lib','prepare_cidr.rb')
  load rb_file if File.exists?(rb_file) or raise e
end
require 'puppetx/l23_network_scheme'

Puppet::Parser::Functions::newfunction(:get_default_gateways, :type => :rvalue, :doc => <<-EOS
    Parse network_scheme and return list of default gateways,
    ordered by its metrics

    Returns [] if no gateways.

    EOS
  ) do |argv|

  cfg = L23network::Scheme.get_config(lookupvar('l3_fqdn_hostname'))
  if cfg.nil?
    raise(Puppet::ParseError, "get_default_gateways(): You must call prepare_network_config(...) first!")
  end

  endpoints = cfg[:endpoints]
  if ! endpoints.is_a? Hash
      Puppet::ParseError("get_default_gateways(): Section 'endpoints' should be a hash.")
  end

  rv = []
  endpoints.each do |ep_name, ep_props|
    next if ep_props[:gateway].nil?
    rv << {
      :m  => (ep_props[:gateway_metric] or 0),
      :g => ep_props[:gateway]
    }
  end
  return [] if rv.empty?
  rv.sort_by{|a| a[:m]}.map{|t| t[:g]}
end

# vim: set ts=2 sw=2 et :
