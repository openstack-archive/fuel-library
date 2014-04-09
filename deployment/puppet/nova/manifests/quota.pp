# class for overriding the default quota settings.
class nova::quota(
  $quota_instances = 10,
  $quota_cores = 20,
  $quota_ram = 51200,
  $quota_volumes = 10,
  $quota_gigabytes = 1000,
  $quota_floating_ips = 10,
  $quota_metadata_items = 128,
  $quota_max_injected_files = 5,
  $quota_max_injected_file_content_bytes = 10240,
  $quota_max_injected_file_path_bytes = 255,
  $quota_security_groups = 10,
  $quota_security_group_rules = 20,
  $quota_key_pairs = 10,
  $reservation_expire = 86400,
  $max_age = 0,
  $quota_driver = 'nova.quota.DbQuotaDriver'
) {

  nova_config {
    'DEFAULT/quota_instances':                       value => $quota_instances;
    'DEFAULT/quota_cores':                           value => $quota_cores;
    'DEFAULT/quota_ram':                             value => $quota_ram;
    'DEFAULT/quota_volumes':                         value => $quota_volumes;
    'DEFAULT/quota_gigabytes':                       value => $quota_gigabytes;
    'DEFAULT/quota_floating_ips':                    value => $quota_floating_ips;
    'DEFAULT/quota_metadata_items':                  value => $quota_metadata_items;
    'DEFAULT/quota_max_injected_files':              value => $quota_max_injected_files;
    'DEFAULT/quota_max_injected_file_content_bytes': value => $quota_max_injected_file_content_bytes;
    'DEFAULT/quota_max_injected_file_path_bytes':    value => $quota_max_injected_file_path_bytes;
    'DEFAULT/quota_security_groups':                 value => $quota_security_groups;
    'DEFAULT/quota_security_group_rules':            value => $quota_security_group_rules;
    'DEFAULT/quota_key_pairs':                       value => $quota_key_pairs;
    'DEFAULT/reservation_expire':                    value => $reservation_expire;
    'DEFAULT/max_age':                               value => $max_age;
    'DEFAULT/quota_driver':                          value => $quota_driver
  }

}
