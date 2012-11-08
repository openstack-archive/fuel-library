# common/manifests/init.pp - Define common infrastructure for modules
# Copyright (C) 2007 David Schmitt <david@schmitt.edv-bus.at>
# See LICENSE for the full license granted to you.

import "defines/*.pp"
import "classes/*.pp"

class common {
	module_dir { [ 'common' ]: }

	file {
		# Module programmers can use /var/lib/puppet/modules/$modulename to save
		# module-local data, e.g. for constructing config files. See module_dir
		# for details
		"/var/lib/puppet/modules":
			ensure => directory,
			source => "puppet:///modules/common/modules",
			ignore => ".ignore",
			recurse => true, purge => true, force => true,
			mode => 0755, owner => root, group => 0;
	}
}

include common

# common packages
class pkg::openssl { package { openssl: ensure => installed } }
class pkg::rsync { package { rsync: ensure => installed } }

