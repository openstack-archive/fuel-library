require 'ipaddr'

Puppet::Parser::Functions::newfunction(:format_allocation_pools, :type => :rvalue, :arity => -2, :doc => <<-EOS
This function gets floating ranges and format allocation_pools attribute value for neutron subnet resource.
EOS
) do |args|

  floating_ranges = Array(args[0])
  floating_cidr = IPAddr.new(args[1]) rescue false

  raise(
    ArgumentError,
    'format_allocation_pools(): Requires array/string [start_ip:end_ip] as first argument'
  ) unless floating_ranges.all? { |r| r =~ /\S+:\S+/ }

  # return mapped ranges as is if cidr ain't provided
  return floating_ranges.map { |r| 'start=%s,end=%s' % r.split(':')} unless floating_cidr

  # walk through the ranges and skip an entry
  # if it doesn't match the network cidr
  floating_ranges.reduce([]) do |alloc_pools, srange|
    range = srange.split(':')
    if range.all? { |ip| floating_cidr.include? ip }
      alloc_pools << 'start=%s,end=%s' % range
    else
      warning("#{srange} doesn't match #{floating_cidr.inspect}, skip it over")
    end
    alloc_pools
  end
end
