require 'rubygems'
require 'json'
require 'hiera'
require 'ipaddr'

Puppet::Parser::Functions::newfunction(:direct_networks, :type => :rvalue, :doc => <<-EOS
 parses network scheme and returns networks
 directly attached to the host
 EOS
 ) do |argv|
  
  endpoints = argv[0]

  ENV['LANG'] = 'C'
  $hiera = Hiera.new(:config => '/etc/hiera.yaml')

  endpoints = $hiera.lookup('network_scheme', false, {})[endpoints]

  ip = []
  endpoints.each do |x,y|
    ip.push(y['IP'].join(' ')) if y.is_a?(Hash) and y.has_key?('IP')
  end

  return ip.map! { |a|  IPAddr.new(a).to_s + "/" + a.split('/')[1]}.join(' ')
end

