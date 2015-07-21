##2015-07-08 - 6.0.0
###Summary

This is a backwards-incompatible major release for OpenStack Kilo.

####Backwards-incompatible changes
- MySQL: change default MySQL collate to utf8_general_ci

####Features
- Puppet 4.x support
- Add db::postgresql to openstacklib
- Implement openstacklib::wsgi::apache
- Move openstackclient parent provider to openstacklib
- Keystone V3 API support
- Restructures authentication for resource providers

####Bugfixes
- Properly handle policy values containing spaces

####Maintenance
- Bump mysql version to 3.x
- Acceptance tests with Beaker

##2015-06-17 - 5.1.0
###Summary

This is a feature and bugfix release in the Juno series.

####Features
- Adding augeas insertion check

####Bugfixes
- MySQL: change default MySQL collate to utf8_general_ci

####Maintenance
- Update .gitreview file for project rename
- spec: pin rspec-puppet to 1.0.1

##2014-11-25 - 5.0.0
###Summary

Initial release for Juno.
