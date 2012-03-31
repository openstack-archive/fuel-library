#
# used to configure file backends for glance
#
#  $filesystem_store_datadir - Location where dist images are stored when
#  default_store == file.
#  Optional. Default: /var/lib/glance/images/
class glance::backend::file(
  $filesystem_store_datadir = '/var/lib/glance/images/'
) inherits glance::api {

  # set file as default store
  class { 'glance::backend':
    default_store => 'file',
  }

  # configure directory where files should be stored
  glance::api::config { 'file':
    config => {
      'filesystem_store_datadir' => $filesystem_store_datadir
    },
    order  => '05',
  }
}
