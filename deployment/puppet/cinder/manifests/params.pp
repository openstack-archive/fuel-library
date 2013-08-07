#
class cinder::params {

  $cinder_conf = '/etc/cinder/cinder.conf'
  $cinder_paste_api_ini = '/etc/cinder/api-paste.ini'

  case $::osfamily {
    'Debian': {
      $package_name      = 'cinder-common'
      $api_package       = 'cinder-api'
      $api_service       = 'cinder-api'
      $scheduler_package = 'cinder-scheduler'
      $scheduler_service = 'cinder-scheduler'
      $volume_package    = 'cinder-volume'
      $volume_service    = 'cinder-volume'
      $db_sync_command   = 'cinder-manage db sync'

      $tgt_package_name  = 'tgt'
      $tgt_service_name  = 'tgt'
      $python_path       = 'python2.7/dist-packages'
      $qemuimg_package_name = 'qemu-utils'
    }

    'RedHat': {
      $qemuimg_package_name = $::operatingsystem ? {
                               redhat => 'qemu-img-rhev',
                               default => 'qemu-img',
                              }
      $package_name      = 'openstack-cinder'
      $api_package       = false
      $scheduler_package = false
      $volume_package    = false

      $api_service       = 'openstack-cinder-api'
      $scheduler_service = 'openstack-cinder-scheduler'
      $volume_service    = 'openstack-cinder-volume'

      $db_sync_command   = 'cinder-manage db sync'

      $tgt_package_name  = 'scsi-target-utils'
      $tgt_service_name  = 'tgtd'
      $python_path       = 'python2.6/site-packages'
    }
  }
}
