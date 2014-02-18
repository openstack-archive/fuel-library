class murano::cirros (
  $os_tenant_name   = 'admin',
  $os_username      = 'admin',
  $os_password      = 'ChangeMe',
  $os_auth_url      = 'http://127.0.0.1:5000/v2.0/',
  $disk_format      = 'raw',
  $container_format = 'bare',
  $public           = 'true',
  $img_name         = 'TestVm',
  $os_name          = 'cirros',
) {

  # this code is not used because we are using Astute to upload image to Glance
  # But it's left here because it could be useful for someone who is trying
  # to use this module outside Fuel

  #case $::osfamily {
  #  'RedHat': {
  #    exec { 'upload-img':
  #      command => "/usr/bin/glance -N ${os_auth_url} -T ${os_tenant_name} -I ${os_username} -K ${os_password} image-create --name=${img_name} --is-public=${public} --container-format=${container_format} --disk-format=${disk_format} --property murano_image_info=\'{\"title\": \"Murano Demo\", \"type\": \"cirros.demo\"}\'< /tmp/murano-cirros.qcow2",
  #      unless => "/usr/bin/glance -N ${os_auth_url} -T ${os_tenant_name} -I ${os_username} -K ${os_password} index && (/usr/bin/glance -N ${os_auth_url} -T ${os_tenant_name} -I ${os_username} -K ${os_password} index | grep ${img_name})",
  #    }
  #  }
  #  'Debian': {
  #    exec { 'upload-img':
  #      command => "/usr/bin/glance -N ${os_auth_url} -T ${os_tenant_name} -I ${os_username} -K ${os_password} image-create  --name=${img_name} --is_public=${public} --container_format=${container_format} --disk_format=${disk_format}  --property murano_image_info=\'{\"title\": \"Murano Demo\", \"type\": \"cirros.demo\"}\'< /tmp/murano-cirros.qcow2",
  #      unless => "/usr/bin/glance -N ${os_auth_url} -T ${os_tenant_name} -I ${os_username} -K ${os_password} index && (/usr/bin/glance -N ${os_auth_url} -T ${os_tenant_name} -I ${os_username} -K ${os_password} index | grep ${img_name})",
  #    }
  #  }
  #}

}
