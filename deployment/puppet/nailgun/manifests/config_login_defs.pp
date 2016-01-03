#
# nailgun::config_login_defs manages settings in the /etc/login.defs
#
# [login_defs_elem] Hash with param and value of the managed line
#

define nailgun::config_login_defs (

  $login_defs_elem = $title,

){

  # manage settings in the /etc/login.defs
  file_line { "login.defs: ${login_defs_elem['param']}":
    path  => '/etc/login.defs',
    line  => "${login_defs_elem['param']} ${login_defs_elem['value']}",
    match => "^${login_defs_elem['param']}.*$",
  }

}
