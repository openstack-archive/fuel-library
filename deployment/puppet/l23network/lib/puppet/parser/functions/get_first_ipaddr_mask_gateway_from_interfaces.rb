module Puppet::Parser::Functions
  newfunction(:get_first_ipaddr_mask_gateway_from_interfaces, :type => :rvalue) do |args|
    rv = []
    args.each do |iface|
      ipaddr = "::ipaddress_#{$iface}"
      ipaddr = lookupvar(ipaddr)
      if !ipaddr or (ipaddr == :undefined)
        next
      else
        ipmask = "::netmask_#{$iface}"
        ipmask = lookupvar(ipmask)
        if ipmask and ipmask != :undefined
          break
        end
      end
    end
    if ipaddr
      [ipaddr, ipmask]
    else
      [nil, nil]
    end
  end
end