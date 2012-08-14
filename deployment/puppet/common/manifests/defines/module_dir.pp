# common/manifests/defines/module_dir.pp -- create a default directory
# for storing module specific information
#
# Copyright (C) 2007 David Schmitt <david@schmitt.edv-bus.at>
# See LICENSE for the full license granted to you.

# Use this variable to reference the base path. Thus you are safe from any
# changes.
$module_dir_path = '/var/lib/puppet/modules'

# A module_dir is a storage place for all the stuff a module might want to
# store. According to the FHS, this should go to /var/lib. Since this is a part
# of puppet, the full path is /var/lib/puppet/modules/${name}. Every module
# should # prefix its module_dirs with its name.
# 
# By default, the module_dir is loaded from "puppet:///${name}/module_dir". If
# that doesn't exist an empty directory is taken as source. The directory is
# purged so that modules do not have to worry about removing cruft.
# 
# Usage:
#  module_dir { ["common", "common/dir1", "common/dir2" ]: }
define module_dir (
		$mode = 0644,
		$owner = root,
		$group = 0
	)
{
	$dir = "${module_dir_path}/${name}"
	if defined(File[$dir]) {
		debug("${dir} already defined")
	} else {
		file {
			$dir:
				source => [ "puppet:///modules/${name}/module_dir", "puppet:///modules/common/empty"],
				checksum => md5,
				# ignore the placeholder
				ignore => '\.ignore', 
				recurse => true, purge => true, force => true,
				mode => $mode, owner => $owner, group => $group;
		}
	}
}

