class keystone::ldap {
  keystone::config { 'ldap': 
    order => '01',
  }
}
