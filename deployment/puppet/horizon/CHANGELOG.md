##2015-07-08 - 6.0.0
###Summary

This is a backwards-incompatible major release for OpenStack Kilo.

####Backwards-incompatible changes
- Remove some old deprecated parameters

####Features
- Puppet 4.x support
- Sort policy files in local_settings.py
- Add support for Neutron DVR and L3 HA options
- Collect static files before compressing them
- Add support to add Tuskar-ui config to local_settings
- Add support for WEBROOT in local_settings
- Add 'log_handler' parameter

####Maintenance
- Acceptance tests with Beaker
- Fix spec tests for RSpec 3.x and Puppet 4.x

##2015-06-17 - 5.1.0
###Summary

This is a feature and bugfix release in the Juno series.

####Features
- Add support for the configuration of OPENSTACK_CINDER_FEATURES

####Bugfixes
- Sort policy files in local_settings.py

####Maintenance
- spec: pin rspec-puppet to 1.0.1
- Pin puppetlabs-concat to 1.2.1 in fixtures
- Update .gitreview file for project rename

##2014-11-25 - 5.0.0
###Summary

This is a backwards-incompatible major release for OpenStack Juno.

####Backwards-incompatible changes
- Switch the default log level to INFO from DEBUG

####Features
- Use concat to manage local_settings.py
- Add parameters to configure policy files in horizon class
- Add parameter django_session_engine to horizon class
- Change cache_server_ip in horizon class to accept arrays

####Bugfixes
- Fix the default value of compress_offline parameter
- Fix Apache config file default
- Stop setting wsgi_socket_prefix since the apache module takes care of it
- Add workaround for puppet's handling of undef for setting the vhost bind
  address
- Fix the default MSSQL port in security group rules

##2014-10-16 - 4.2.0
###Summary

This is a feature and bugfix release in the Icehouse series.

####Features
- Add parameters to configure ALLOWED_HOSTS in settings_local.y and
  ServerAlias in apache, no longer requiring these values to be the fqdn
- Add support for secure cookies

####Bugfixes
- Fix removal of vhost conf file

##2014-06-19 - 4.1.0
###Summary

####Features
- Add option to set temporary upload directory for images

####Bugfixes
- Ensure ssl wsgi_process_group is the same as wsgi_daemon_process

####Maintenance
- Pin major gems

##2014-05-01 - 4.0.0
###Summary

This is a major release for OpenStack Icehouse but contains no API-breaking
changes.

####Features
- Add support to pass extra parameters to vhost
- Add support to ensure online cache is present and can be refreshed
- Add support to configure OPENSTACK_HYPERVISOR_FEATURES settings,
  AVAILABLE_REGIONS, OPENSTACK_NEUTRON_NETWORK
- Add support to disable configuration of Apache

####Bugfixes
- Fix log ownership and WSGIProcess* settings for Red Hat releases
- Fix overriding of policy files in local settings
- Fix SSL bugs
- Improve WSGI configuration

####Maintenance

##2014-03-26 - 3.1.0
###Summary

This is a feature release in the Havana series.

####Features
- Add option parameterize OPENSTACK_NEUTRON_NETWORK settings

##2014-02-14 - 3.0.1
###Summary

This is a bugfix release in the Havana series.

####Bugfixes
- Add COMPRESS_OFFLINE option to local_settings to fix broken Ubuntu
  installation

####Maintenance

##2014-01-16 - 3.0.0
###Summary

This is a backwards-incompatible major release for OpenStack Havana.

####Backwards-incompatible changes
- Update user and group for Debian family OSes
- Update policy files for RedHat family OSes
- Change keystone_default_role to _member_

####Features
- Enable SSL support with cert/key
- Introduce new parameters: keystone_url, help_url, endpoint type

####Bugfixes
- Improve default logging configuration
- Fix bug to set LOGOUT_URL properly
- Fix user/group regression for Debian

####Maintenance

##2013-10-07 - 2.2.0
###Summary

This is a bugfix release in the Grizzly series.

####Bugfixes
- Fixed apache 0.9.0 incompatability

####Maintenance
- Various lint fixes

##2013-08-07 - 2.1.0
###Summary

This is a bugfix release in the Grizzly series.

####Bugfixes
- Update local_settings.py

####Maintenance
- Pin Apache module version
- Various lint fixes

##2013-06-24 - 2.0.0
###Summary

Initial release on StackForge.

####Features
- httpd config now managed on every platform
- Provide option to enable Horizon's display of block device mount points
