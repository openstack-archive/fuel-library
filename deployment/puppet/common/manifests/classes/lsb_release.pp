# common/manifests/classes/lsb_release.pp -- request the installation of
# lsb_release to get to lsbdistcodename, which is used throughout the manifests
#
# Copyright (C) 2007 David Schmitt <david@schmitt.edv-bus.at>
# See LICENSE for the full license granted to you.

# Changelog:
# 2007-08-26: micah <micah@riseup.net> reported, that lsb_release can report
#	nonsensical values for lsbdistcodename; assert_lsbdistcodename now
#	recognises "n/a" and acts accordingly

# This lightweight class only asserts that $lsbdistcodename is set.
# If the assertion fails, an error is printed on the server
# 
# To fail individual resources on a missing lsbdistcodename, require
# Exec[assert_lsbdistcodename] on the specific resource
#
# This is just one example of how you could avoid evaluation of parts of the
# manifest, before a bootstrapping class has enabled all the necessary goodies.
class assert_lsbdistcodename {

	case $lsbdistcodename {
		'': {
			err("Please install lsb_release or set facter_lsbdistcodename in the environment of $fqdn")
			exec { "false # assert_lsbdistcodename": alias => assert_lsbdistcodename, loglevel => err }
		}
		'n/a': {
			case $operatingsystem {
				"Debian": {
					err("lsb_release was unable to report your distcodename; This seems to indicate a broken apt/sources.list on $fqdn")
				}
				default: {
					err("lsb_release was unable to report your distcodename; please set facter_lsbdistcodename in the environment of $fqdn")
				}
			}
			exec { "false # assert_lsbdistcodename": alias => assert_lsbdistcodename, loglevel => err }
		}
		default: {
			exec { "true # assert_lsbdistcodename": alias => assert_lsbdistcodename, loglevel => debug }
			exec { "true # require_lsbdistcodename": alias => require_lsbdistcodename, loglevel => debug }
		}
	}

}

# To fail the complete compilation on a missing $lsbdistcodename, include this class
class require_lsbdistcodename inherits assert_lsbdistcodename {
	exec { "false # require_lsbdistcodename": require => Exec[require_lsbdistcodename], loglevel => err }
}
