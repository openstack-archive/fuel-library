require 'puppetx/l23_network_scheme'

module Puppet::Parser::Functions
  newfunction(:network_config_prepared,
    :arity => 0,
    :type => :rvalue,
    :doc => <<-EOS
    Check if network config is already prepared
    EOS
  ) do |argv|
    L23network::Scheme.has_config?
  end
end
