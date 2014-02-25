#
# used to configure file backends for glance
#
#  $filesystem_store_datadir - Location where dist images are stored when
#  default_store == file.
#  Optional. Default: /var/lib/glance/images/
class glance::backend::file(
) inherits glance::api {

  glance_api_config {
    'DEFAULT/default_store':  value => 'file';
  }

}
