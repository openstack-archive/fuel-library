def prepare_cidr(cidr)
  if ! cidr.is_a?(String)
    raise(Puppet::ParseError, "Can't recognize IP address in non-string data.")
  end

  re_groups = /^(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\/(\d{1,2})$/.match(cidr)
  if ! re_groups or re_groups[2].to_i > 32
    raise(Puppet::ParseError, "cidr_to_ipaddr(): Wrong CIDR: '#{cidr}'.")
  end 
  
  for octet in re_groups[1].split('.')
    raise(Puppet::ParseError, "cidr_to_ipaddr(): Wrong CIDR: '#{cidr}'.") if octet.to_i > 255
  end
  
  return re_groups[1], re_groups[2].to_i
end
