# This class will upload test cirros image into the glance

class vmware::img::cirros (
  $os_tenant_name = 'admin',
  $os_username = 'admin',
  $os_password = 'admin',
  $os_auth_url = 'http://127.0.0.1:5000/v2.0/',
  $disk_format = 'vmdk',
  $container_format = 'bare',
  $public = 'true',
  $img_name = 'TestVMWare',
  $os_name = 'cirros',
) {

  package { 'cirros-testvmware':
    ensure => "present"
  }
  ->
case $::osfamily { # open case
  'RedHat': { # open RedHat
  exec { 'upload-img': # open exec

    command => "/usr/bin/glance -N ${os_auth_url} -T ${os_tenant_name} -I ${os_username} -K ${os_password} image-create --name=${img_name} --is-public=${public} --container-format=${container_format} --disk-format=${disk_format} --property vmware_disktype=sparse --property vmware_adaptertype=ide --property hypervisor_type=vmware < /opt/vm/cirros-x86_64-disk.vmdk",
    unless => "/usr/bin/glance -N ${os_auth_url} -T ${os_tenant_name} -I ${os_username} -K ${os_password} index && (/usr/bin/glance -N ${os_auth_url} -T ${os_tenant_name} -I ${os_username} -K ${os_password} index | grep ${img_name})",

  } # close exec
  } # close RedHat

  'Debian': { # open Ubuntu
  exec { 'upload-img': # open exec

    command => "/usr/bin/glance -N ${os_auth_url} -T ${os_tenant_name} -I ${os_username} -K ${os_password} image-create --name=${img_name} --is-public=${public} --container-format=${container_format} --disk-format=${disk_format} --property vmware_disktype=sparse --property vmware_adaptertype=ide --property hypervisor_type=vmware < /usr/share/cirros-testvmware/cirros-x86_64-disk.vmdk",
    unless => "/usr/bin/glance -N ${os_auth_url} -T ${os_tenant_name} -I ${os_username} -K ${os_password} index && (/usr/bin/glance -N ${os_auth_url} -T ${os_tenant_name} -I     ${os_username} -K ${os_password} index | grep ${img_name})",

  } # close exec
  } # close Ubuntu

} # close case
} # close class
