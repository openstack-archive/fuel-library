# Fact: l2_ovs_vlan_splinters_need_for
#
# Purpose: Return list of intefaces, that needs for enable OVS VLAN splinters.
#
Facter.add(:l2_ovs_vlan_splinters_need_for) do
  need = Facter.value(:kernelmajversion) =~ /^(2.\d|3.[0-2])/
  need = need.nil?  ?  false  :  true
  rv = []
  supported_drivers = [
    '8139cp', 'acenic', 'amd8111e', 'atl1c', 'ATL1E', 'atl1', 'atl2',
    'be2net', 'bna', 'bnx2', 'bnx2x', 'cnic', 'cxgb', 'cxgb3',
    'e1000', 'e1000e', 'enic', 'forcedeth', 'igb', 'igbvf', 'ixgb',
    'ixgbe', 'jme', 'ml4x_core', 'ns83820', 'qlge', 'r8169', 'S2IO',
    'sky2', 'starfire', 'tehuti', 'tg3', 'typhoon', 'via-velocity',
    'vxge', 'gianfar', 'ehea', 'stmmac', 'vmxnet3' #, 'pcnet32'
  ]
  interfaces = Facter.value(:interfaces)
  if need and interfaces
    for dev in interfaces.split(',').select{|x| x=~/^eth/} do
      basedir = "/sys/class/net/#{dev}"
      if ! (File.exists?(basedir) and File.exists?("#{basedir}/device/") and File.exists?("#{basedir}/device/uevent"))
        next
      end
      driver = File.open("#{basedir}/device/uevent"){ |f| f.read }.split("\n").select{|x| x=~/^DRIVER=/}[0].split('=')[1]
      if supported_drivers.index(driver)
        rv.insert(-1, dev)
      end
    end
  end
  setcode do
    rv.sort().join(',')
  end
end

# vim: set ts=2 sw=2 et :