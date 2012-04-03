#
# used to configure file backends for glance
#
#  $filesystem_store_datadir - Location where dist images are stored when
#  default_store == file.
#  Optional. Default: /var/lib/glance/images/
class glance::backend::file(
  $filesystem_store_datadir = '/var/lib/glance/images/'
) inherits glance::api {

  #
  # modeled as its own config define so that any attempts to
  # define multiple backends will fail
  #
  glance::api::config { 'backend':
    config => {
      'default_store' => 'file',
    },
    order  => '04',
  }

  # configure directory where files should be stored
  glance::api::config { 'file':
    config => {
      'filesystem_store_datadir' => $filesystem_store_datadir
    },
    order  => '05',
  }
}
