class openstack::img::cirros (
  $os_tenant_name = 'openstack',
  $os_username = 'admin',
  $os_password = 'ChangeMe',
  $os_auth_url = 'http://localhost:5000/v2.0/',
  $disk_format,
  $container_format,
  $public = 'true',
  $img_name = 'cirros',
  $os_name = 'cirros',
  $img = 'https://launchpadlibrarian.net/83305348/cirros-0.3.0-x86_64-disk.img',
) {

  exec { 'img':
    command => "/usr/bin/curl ${img} -o /tmp/cirros.img",
    creates => "/tmp/cirros.img",
  }->

  exec { 'upload-img':
    command => "/usr/bin/glance -N ${os_auth_url} -T ${os_tenant_name} -I ${os_username} -K ${os_password} add name=${img_name} is_public=${public} container_format=${container_format} disk_format=${disk_format} distro=${os_name} < /tmp/cirros.img",
  }
  

}
