class { 'Settings':
  name => 'Settings',
}

class { 'main':
  name => 'main',
}

exec { 'generate_vms':
  command => '/usr/bin/generate_vms.sh /etc/libvirt/qemu /var/lib/nova',
  path    => ['/usr/sbin', '/usr/bin', '/sbin', '/bin'],
  require => ['File[/var/lib/nova]', 'File[/etc/libvirt/qemu/autostart]'],
}

file { '/etc/libvirt/qemu/autostart':
  ensure  => 'directory',
  path    => '/etc/libvirt/qemu/autostart',
  require => ['Package[qemu-utils]', 'Package[qemu-kvm]', 'Package[libvirt-bin]', 'Package[xmlstarlet]'],
}

file { '/var/lib/nova/template_1_vm.xml':
  content => '<domain type='kvm'>
  <name>1_vm</name>
  <memory unit='GiB'></memory>
  <vcpu placement='static'>2</vcpu>
  <os>
    <type arch='x86_64' machine='pc-i440fx-trusty'>hvm</type>
    <boot dev='network'/>
    <boot dev='hd'/>
  </os>
  <features>
    <acpi/>
    <apic/>
    <pae/>
  </features>
  <clock offset='utc'/>
  <on_poweroff>destroy</on_poweroff>
  <on_reboot>restart</on_reboot>
  <on_crash>restart</on_crash>
  <devices>
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2' cache='writeback'/>
      <source file='/var/lib/nova/1_vm.img' size=''/>
      <target dev='vda' bus='virtio'/>
    </disk>
    <controller type='usb' index='0'>
    </controller>
    <controller type='ide' index='0'>
    </controller>
    <controller type='pci' index='0' model='pci-root'/>
    <interface type='bridge'>
      <source bridge='br-fw-admin'/>
      <model type='virtio'/>
    </interface>
    <interface type='bridge'>
      <source bridge='br-ex'/>
      <model type='virtio'/>
    </interface>
    <interface type='bridge'>
      <source bridge='br-storage'/>
      <model type='virtio'/>
    </interface>
    <interface type='bridge'>
      <source bridge='br-mgmt'/>
      <model type='virtio'/>
    </interface>
    <interface type='bridge'>
      <source bridge='br-mesh'/>
      <model type='virtio'/>
    </interface>
    <serial type='pty'>
      <target port='0'/>
    </serial>
    <console type='pty'>
      <target type='serial' port='0'/>
    </console>
    <input type='mouse' bus='ps2'/>
    <input type='keyboard' bus='ps2'/>
    <graphics type='vnc' port='-1' autoport='yes'/>
    <video>
      <model type='cirrus' vram='9216' heads='1'/>
    </video>
    <memballoon model='virtio'>
    </memballoon>
  </devices>
</domain>
',
  group   => 'root',
  owner   => 'root',
  path    => '/var/lib/nova/template_1_vm.xml',
}

file { '/var/lib/nova/template_2_vm.xml':
  content => '<domain type='kvm'>
  <name>2_vm</name>
  <memory unit='GiB'></memory>
  <vcpu placement='static'>4</vcpu>
  <os>
    <type arch='x86_64' machine='pc-i440fx-trusty'>hvm</type>
    <boot dev='network'/>
    <boot dev='hd'/>
  </os>
  <features>
    <acpi/>
    <apic/>
    <pae/>
  </features>
  <clock offset='utc'/>
  <on_poweroff>destroy</on_poweroff>
  <on_reboot>restart</on_reboot>
  <on_crash>restart</on_crash>
  <devices>
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2' cache='writeback'/>
      <source file='/var/lib/nova/2_vm.img' size=''/>
      <target dev='vda' bus='virtio'/>
    </disk>
    <controller type='usb' index='0'>
    </controller>
    <controller type='ide' index='0'>
    </controller>
    <controller type='pci' index='0' model='pci-root'/>
    <interface type='bridge'>
      <source bridge='br-fw-admin'/>
      <model type='virtio'/>
    </interface>
    <interface type='bridge'>
      <source bridge='br-ex'/>
      <model type='virtio'/>
    </interface>
    <interface type='bridge'>
      <source bridge='br-storage'/>
      <model type='virtio'/>
    </interface>
    <interface type='bridge'>
      <source bridge='br-mgmt'/>
      <model type='virtio'/>
    </interface>
    <interface type='bridge'>
      <source bridge='br-mesh'/>
      <model type='virtio'/>
    </interface>
    <serial type='pty'>
      <target port='0'/>
    </serial>
    <console type='pty'>
      <target type='serial' port='0'/>
    </console>
    <input type='mouse' bus='ps2'/>
    <input type='keyboard' bus='ps2'/>
    <graphics type='vnc' port='-1' autoport='yes'/>
    <video>
      <model type='cirrus' vram='9216' heads='1'/>
    </video>
    <memballoon model='virtio'>
    </memballoon>
  </devices>
</domain>
',
  group   => 'root',
  owner   => 'root',
  path    => '/var/lib/nova/template_2_vm.xml',
}

file { '/var/lib/nova/template_3_vm.xml':
  content => '<domain type='kvm'>
  <name>3_vm</name>
  <memory unit='GiB'></memory>
  <vcpu placement='static'></vcpu>
  <os>
    <type arch='x86_64' machine='pc-i440fx-trusty'>hvm</type>
    <boot dev='network'/>
    <boot dev='hd'/>
  </os>
  <features>
    <acpi/>
    <apic/>
    <pae/>
  </features>
  <clock offset='utc'/>
  <on_poweroff>destroy</on_poweroff>
  <on_reboot>restart</on_reboot>
  <on_crash>restart</on_crash>
  <devices>
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2' cache='writeback'/>
      <source file='/var/lib/nova/3_vm.img' size=''/>
      <target dev='vda' bus='virtio'/>
    </disk>
    <controller type='usb' index='0'>
    </controller>
    <controller type='ide' index='0'>
    </controller>
    <controller type='pci' index='0' model='pci-root'/>
    <interface type='bridge'>
      <source bridge='br-fw-admin'/>
      <model type='virtio'/>
    </interface>
    <interface type='bridge'>
      <source bridge='br-ex'/>
      <model type='virtio'/>
    </interface>
    <interface type='bridge'>
      <source bridge='br-storage'/>
      <model type='virtio'/>
    </interface>
    <interface type='bridge'>
      <source bridge='br-mgmt'/>
      <model type='virtio'/>
    </interface>
    <interface type='bridge'>
      <source bridge='br-mesh'/>
      <model type='virtio'/>
    </interface>
    <serial type='pty'>
      <target port='0'/>
    </serial>
    <console type='pty'>
      <target type='serial' port='0'/>
    </console>
    <input type='mouse' bus='ps2'/>
    <input type='keyboard' bus='ps2'/>
    <graphics type='vnc' port='-1' autoport='yes'/>
    <video>
      <model type='cirrus' vram='9216' heads='1'/>
    </video>
    <memballoon model='virtio'>
    </memballoon>
  </devices>
</domain>
',
  group   => 'root',
  owner   => 'root',
  path    => '/var/lib/nova/template_3_vm.xml',
}

file { '/var/lib/nova':
  ensure => 'directory',
  path   => '/var/lib/nova',
}

package { 'libvirt-bin':
  ensure => 'installed',
  name   => 'libvirt-bin',
}

package { 'qemu-kvm':
  ensure => 'installed',
  name   => 'qemu-kvm',
}

package { 'qemu-utils':
  ensure => 'installed',
  name   => 'qemu-utils',
}

package { 'xmlstarlet':
  ensure => 'installed',
  name   => 'xmlstarlet',
}

service { 'libvirtd':
  ensure  => 'running',
  before  => 'Exec[generate_vms]',
  name    => 'libvirtd',
  require => ['Package[qemu-utils]', 'Package[qemu-kvm]', 'Package[libvirt-bin]', 'Package[xmlstarlet]'],
}

stage { 'main':
  name => 'main',
}

vm_config { '{"id"=>1, "cpu"=>2, "ram"=>3}':
  before  => 'Exec[generate_vms]',
  name    => '{"id"=>1, "cpu"=>2, "ram"=>3}',
  require => 'File[/var/lib/nova]',
}

vm_config { '{"id"=>2, "cpu"=>4}':
  before  => 'Exec[generate_vms]',
  name    => '{"id"=>2, "cpu"=>4}',
  require => 'File[/var/lib/nova]',
}

vm_config { '{"id"=>3}':
  before  => 'Exec[generate_vms]',
  name    => '{"id"=>3}',
  require => 'File[/var/lib/nova]',
}

