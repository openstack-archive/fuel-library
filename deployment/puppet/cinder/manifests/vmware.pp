# ==Define: cinder::vmware
#
# Creates vmdk specific disk file type & clone type.
#
# === Parameters
#
# [*os_password*]
#   (required) The keystone tenant:username password.
#
# [*os_tenant_name*]
#   (optional) The keystone tenant name. Defaults to 'admin'.
#
# [*os_username*]
#   (optional) The keystone user name. Defaults to 'admin.
#
# [*os_auth_url*]
#   (optional) The keystone auth url. Defaults to 'http://127.0.0.1:5000/v2.0/'.
#
class cinder::vmware (
  $os_password,
  $os_tenant_name = 'admin',
  $os_username    = 'admin',
  $os_auth_url    = 'http://127.0.0.1:5000/v2.0/'
  ) {

  Cinder::Type {
    os_password     => $os_password,
    os_tenant_name  => $os_tenant_name,
    os_username     => $os_username,
    os_auth_url     => $os_auth_url
  }

  cinder::type {'vmware-thin':
    set_value => 'thin',
    set_key   => 'vmware:vmdk_type'
  }
  cinder::type {'vmware-thick':
    set_value => 'thick',
    set_key   => 'vmware:vmdk_type'
  }
  cinder::type {'vmware-eagerZeroedThick':
    set_value => 'eagerZeroedThick',
    set_key   => 'vmware:vmdk_type'
  }
  cinder::type {'vmware-full':
    set_value => 'full',
    set_key   => 'vmware:clone_type'
  }
  cinder::type {'vmware-linked':
    set_value => 'linked',
    set_key   => 'vmware:clone_type'
  }
}