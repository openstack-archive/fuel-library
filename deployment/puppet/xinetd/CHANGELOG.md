##2015-02-10 - Release 1.5.0
###Summary
This release adds some new parameters and also pins to rspec-puppet 1.x until migration.

####Features
- New parameters in `class xinetd`
  - `package_ensure`
  - `purge_confdir`
- New parameter in `xinetd::service`
  - `nice`

##2015-01-20 - Release 1.4.0
###Summary

This release adds support for Gentoo and improves FreeBSD support

####Features
- Gentoo support added
- Better defaults for group for FreeBSD
- Add deprecation warning for `$xtype` parameter

##2014-07-15 - Release 1.3.1
###Summary

This release merely updates metadata.json so the module can be uninstalled and
upgraded via the puppet module command.

##2014-06-18 - Release 1.3.0
####Features
- Add 'log_on_success', 'log_on_success_operator' and 'log_on_failure_operator
parameters to xinetd::service
- Add 'service_restart', 'service_status', 'service_hasrestart', and
'service_hasstatus' parameters to class xinetd.
- Add support for Amazon Linux.
- License changes to ASLv2
- Testing and documentation updates.

####Bugfixes
- Remove duplicated $log_on_failure parameter

##2013-07-30 - Release 1.2.0
####Features
- Add `confdir`, `conffile`, `package_name`, and `service_name` parameters to
`Class['xinetd']`
- Add support for FreeBSD and Suse.
- Add `log_on_failure`, `service_name`, `groups`, `no_access`, `access_times`,
`log_type`, `only_from`, and `xtype` parameters to `Xinetd::Service` define

####Bugfixes
- Redesign for `xinetd::params` pattern
- Add validation
- Add unit testing

##2012-06-07 - Release 1.1.0
- Add port and bind options to services
- make services deletable

##2010-08-12 - Release 1.0.1
-added documentation

##2010-06-24 - Release 1.0.0
- initial release
