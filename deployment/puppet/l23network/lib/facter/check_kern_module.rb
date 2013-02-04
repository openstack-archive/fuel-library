
def check_kern_module(mod)
  mods = File.readlines("/proc/modules")
  if  mods.select {|x| x =~ mod}.length > 0
    return true
  else
    return false
  end
end

Facter.add('kern_module_ovs_loaded') do
  case Facter.value('osfamily')
    when /(?i)(debian)/
      mod = /^openvswitch_mod\s+/
    when /(?i)(redhat)/
      mod = /^openvswitch\s+/
  end
  setcode do
    check_kern_module(mod)
  end
end

Facter.add('kern_module_bridge_loaded') do
  setcode do
    check_kern_module(/^bridge\s+/)
  end
end
