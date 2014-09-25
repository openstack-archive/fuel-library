# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# == Class: neutron::server::notifications
#
# Configure Notification System Options
#
# === Parameters
#
# [*notify_nova_on_port_status_changes*]
#   (optional) Send notification to nova when port status is active.
#   Defaults to true
#
# [*notify_nova_on_port_data_changes*]
#   (optional) Send notifications to nova when port data (fixed_ips/floatingips)
#   change so nova can update its cache.
#   Defaults to true
#
# [*send_events_interval*]
#   (optional) Number of seconds between sending events to nova if there are
#   any events to send.
#   Defaults to '2'
#
# [*nova_url*]
#   (optional) URL for connection to nova (Only supports one nova region
#   currently).
#   Defaults to 'http://127.0.0.1:8774/v2'
#
# [*nova_admin_auth_url*]
#   (optional) Authorization URL for connection to nova in admin context.
#   Defaults to 'http://127.0.0.1:35357/v2.0'
#
# [*nova_admin_username*]
#   (optional) Username for connection to nova in admin context
#   Defaults to 'nova'
#
# [*nova_admin_tenant_name*]
#   (optional) The name of the admin nova tenant
#   Defaults to 'services'
#
# [*nova_admin_tenant_id*]
#   (optional) The UUID of the admin nova tenant.  If provided this takes
#   precedence over nova_admin_tenant_name.
#
# [*nova_admin_password*]
#   (required) Password for connection to nova in admin context.
#
# [*nova_region_name*]
#   (optional) Name of nova region to use. Useful if keystone manages more than
#   one region.
#   Defaults to 'RegionOne'
#

class neutron::server::notifications (
  $notify_nova_on_port_status_changes = true,
  $notify_nova_on_port_data_changes   = true,
  $send_events_interval               = '2',
  $nova_url                           = 'http://127.0.0.1:8774/v2',
  $nova_admin_auth_url                = 'http://127.0.0.1:35357/v2.0',
  $nova_admin_username                = 'nova',
  $nova_admin_tenant_name             = 'services',
  $nova_admin_tenant_id               = undef,
  $nova_admin_password                = false,
  $nova_region_name                   = 'RegionOne',
) {

  # Depend on the specified keystone_user resource, if it exists.
  Keystone_user <| title == 'nova' |> -> Class[neutron::server::notifications]

  if ! $nova_admin_password {
    fail('nova_admin_password must be set.')
  }

  if ! ( $nova_admin_tenant_id or $nova_admin_tenant_name ) {
    fail('You must provide either nova_admin_tenant_name or nova_admin_tenant_id.')
  }

  neutron_config {
    'DEFAULT/notify_nova_on_port_status_changes': value => $notify_nova_on_port_status_changes;
    'DEFAULT/notify_nova_on_port_data_changes':   value => $notify_nova_on_port_data_changes;
    'DEFAULT/send_events_interval':               value => $send_events_interval;
    'DEFAULT/nova_url':                           value => $nova_url;
    'DEFAULT/nova_admin_auth_url':                value => $nova_admin_auth_url;
    'DEFAULT/nova_admin_username':                value => $nova_admin_username;
    'DEFAULT/nova_admin_password':                value => $nova_admin_password, secret => true;
    'DEFAULT/nova_region_name':                   value => $nova_region_name;
  }

  if $nova_admin_tenant_id {
    neutron_config {
      'DEFAULT/nova_admin_tenant_id': value => $nova_admin_tenant_id;
    }
  } else {
    nova_admin_tenant_id_setter {'nova_admin_tenant_id':
      ensure           => present,
      tenant_name      => $nova_admin_tenant_name,
      auth_url         => $nova_admin_auth_url,
      auth_username    => $nova_admin_username,
      auth_password    => $nova_admin_password,
      auth_tenant_name => $nova_admin_tenant_name,
    }
  }
}
