class openstack_tasks::murano::upload_murano_package {

  notice('MODULAR: murano/upload_murano_package.pp')

  murano::application { 'io.murano' :
    exists_action => 'u'
  }
}
