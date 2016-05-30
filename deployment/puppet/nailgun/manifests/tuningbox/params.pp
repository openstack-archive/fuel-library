class nailgun::tuningbox::params {

  # app settings
  $app_name          = 'tuningbox'
  $package_name      = 'tuning-box'
  $host              = '127.0.0.1'
  $port              = '8082'
  $log_level         = 'DEBUG'
  $config_folder     = '/etc/tuningbox'
  $config_file_path  = "${config_folder}/tuningbox_config.py"
  $uwsgi_config_path = "${config_folder}/uwsgi_nailgun.yaml"
  $log_dir           = "/var/log/tuningbox"
  $log_path          = "${log_dir}/tuningbox.log"
  $log_level         = 'DEBUG'
  $syncdb_script     = 'tuningbox_db_upgrade'
  $app_path          = '/usr/lib/python2.7/site-packages/tuning_box'
  $app_module        = 'tuning_box.app:build_app()'
  $pid_path          = '/var/run/tuningbox.pid'

  # postgres settings
  $db_connection = 'postgresql://tuningbox:tuningbox@localhost/tuningbox'

  # keystone settings
  $keystone_host   = '127.0.0.1'
  $keystone_user   = 'tuningbox'
  $keystone_pass   = 'tuningbox'
  $keystone_tenant = 'services'

  # uwsgi settings
  $uwsgi_packages = [
    'uwsgi',
    'uwsgi-plugin-common',
    'uwsgi-plugin-python'
  ]
}
