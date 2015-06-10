#concat

####Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with concat](#setup)
    * [What concat affects](#what-concat-affects)
    * [Beginning with concat](#beginning-with-concat)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
    * [Defines](#defines)
    * [Parameters](#parameters)
    * [Removed functionality](#removed-functionality)
6. [Limitations - OS compatibility, etc.](#limitations)
7. [Development - Guide for contributing to the module](#development)

##Overview

The concat module lets you construct files from multiple ordered fragments of text.

##Module Description

The concat module lets you gather `concat::fragment` resources from your other modules and order them into a coherent file through a single `concat` resource.

###Beginning with concat

To start using concat you need to create:

* A concat{} resource for the final file.
* One or more concat::fragment{}s.

A minimal example might be:

~~~
concat { '/tmp/file':
  ensure => present,
}

concat::fragment { 'tmpfile':
  target  => '/tmp/file',
  content => 'test contents',
  order   => '01'
}
~~~

##Usage

###Maintain a list of the major modules on a node

To maintain an motd file that lists the modules on one of your nodes, first create a class to frame up the file:

~~~
class motd {
  $motd = '/etc/motd'

  concat { $motd:
    owner => 'root',
    group => 'root',
    mode  => '0644'
  }

  concat::fragment{ 'motd_header':
    target  => $motd,
    content => "\nPuppet modules on this server:\n\n",
    order   => '01'
  }

  # let local users add to the motd by creating a file called
  # /etc/motd.local
  concat::fragment{ 'motd_local':
    target => $motd,
    source => '/etc/motd.local',
    order  => '15'
  }
}

# let other modules register themselves in the motd
define motd::register($content="", $order='10') {
  if $content == "" {
    $body = $name
  } else {
    $body = $content
  }

  concat::fragment{ "motd_fragment_$name":
    target  => '/etc/motd',
    order   => $order,
    content => "    -- $body\n"
  }
}
~~~

Then, in the declarations for each module on the node, add `motd::register{ 'Apache': }` to register the module in the motd.

~~~
class apache {
  include apache::install, apache::config, apache::service

  motd::register{ 'Apache': }
}
~~~

These two steps populate the /etc/motd file with a list of the installed and registered modules, which stays updated even if you just remove the registered modules' `include` lines. System administrators can append text to the list by writing to /etc/motd.local.

When you're finished, the motd file will look something like this:

~~~
  Puppet modules on this server:

    -- Apache
    -- MySQL

  <contents of /etc/motd.local>
~~~

##Reference

###Defines
* `concat`: Manages a file, compiled from one or more text fragments.
* `concat::fragment`: Manages a fragment of text to be compiled into a file.

###Types
* `concat_file`: Generates a file with content from fragments sharing a common unique tag.
* `concat_fragment`: Manages the fragment.

###Parameters

####Define: `concat`

All the parameters listed below are optional.

#####`backup`

Specifies whether (and how) to back up the destination file before overwriting it. Your value gets passed on to Puppet's [native `file` resource](https://docs.puppetlabs.com/references/latest/type.html#file-attribute-backup) for execution. Valid options: 'true', 'false', or a string representing either a target filebucket or a filename extension beginning with ".". Default value: 'puppet'.

#####`ensure`

Specifies whether the destination file should exist. Setting to 'absent' tells Puppet to delete the destination file if it exists, and negates the effect of any other parameters. Valid options: 'present' and 'absent'. Default value: 'present'.

#####`ensure_newline`

Specifies whether to add a line break at the end of each fragment that doesn't already end in one. Valid options: 'true' and 'false'. Default value: 'false'.

#####`force`

Deprecated as of concat v2.0.0. Has no effect.

#####`group`

Specifies a permissions group for the destination file. Valid options: a string containing a group name. Default value: undefined.

#####`mode`

Specifies the permissions mode of the destination file. Valid options: a string containing a permission mode value in octal notation. Default value: '0644'.

#####`order`

Specifies a method for sorting your fragments by name within the destination file. Valid options: 'alpha' (e.g., '1, 10, 2') or 'numeric' (e.g., '1, 2, 10'). Default value: 'alpha'.

You can override this setting for individual fragments by adjusting the `order` parameter in their `concat::fragment` declarations.

#####`owner`

Specifies the owner of the destination file. Valid options: a string containing a username. Default value: undefined.

#####`path`

Specifies a destination file for the combined fragments. Valid options: a string containing an absolute path. Default value: the title of your declared resource.

#####`replace`

Specifies whether to overwrite the destination file if it already exists. Valid options: 'true' and 'false'. Default value: 'true'.

#####`validate_cmd`

Specifies a validation command to apply to the destination file. Requires Puppet version 3.5 or newer. Valid options: a string to be passed to a file resource. Default value: undefined.

#####`warn`

Specifies whether to add a header message at the top of the destination file. Valid options: the booleans 'true' and 'false', or a string to serve as the header. Default value: 'false'.

If you set 'warn' to 'true', `concat` adds the following message:

~~~
# This file is managed by Puppet. DO NOT EDIT.
~~~

####Define: `concat::fragment`

Except where noted, all the below parameters are optional.

#####`content`

Supplies the content of the fragment. **Note**: You must supply either a `content` parameter or a `source` parameter. Valid options: a string. Default value: undef.

#####`ensure`

Deprecated as of concat v2.0.0. Has no effect.

#####`order`

Reorders your fragments within the destination file. Fragments that share the same order number are ordered by name. Valid options: a string (recommended) or an integer. Default value: '10'.

#####`source`

Specifies a file to read into the content of the fragment. **Note**: You must supply either a `content` parameter or a `source` parameter. Valid options: a string or an array, containing one or more Puppet URLs. Default value: undefined.

#####`target`

*Required.* Specifies the destination file of the fragment. Valid options: a string containing the title of the parent `concat` resource.


####Type: `concat_file`

#####`backup`

Specifies whether (and how) to back up the destination file before overwriting it. Your value gets passed on to Puppet's [native `file` resource](https://docs.puppetlabs.com/references/latest/type.html#file-attribute-backup) for execution. Valid options: 'true', 'false', or a string representing either a target filebucket or a filename extension beginning with ".". Default value: 'puppet'.

#####`ensure`

Specifies whether the destination file should exist. Setting to 'absent' tells Puppet to delete the destination file if it exists, and negates the effect of any other parameters. Valid options: 'present' and 'absent'. Default value: 'present'.

#####`ensure_newline`

Specifies whether to add a line break at the end of each fragment that doesn't already end in one. Valid options: 'true' and 'false'. Default value: 'false'.

#####`group`

Specifies a permissions group for the destination file. Valid options: a string containing a group name. Default value: undefined.

#####`mode`

Specifies the permissions mode of the destination file. Valid options: a string containing a permission mode value in octal notation. Default value: '0644'.

#####`order`

Specifies a method for sorting your fragments by name within the destination file. Valid options: 'alpha' (e.g., '1, 10, 2') or 'numeric' (e.g., '1, 2, 10'). Default value: 'numeric'.

You can override this setting for individual fragments by adjusting the `order` parameter in their `concat::fragment` declarations.

#####`owner`

Specifies the owner of the destination file. Valid options: a string containing a username. Default value: undefined.

#####`path`

Specifies a destination file for the combined fragments. Valid options: a string containing an absolute path. Default value: the title of your declared resource.

#####`replace`

Specifies whether to overwrite the destination file if it already exists. Valid options: 'true' and 'false'. Default value: 'true'.

####`tag`

*Required.* Specifies a unique tag reference to collect all concat_fragments with the same tag.

#####`validate_cmd`

Specifies a validation command to apply to the destination file. Requires Puppet version 3.5 or newer. Valid options: a string to be passed to a file resource. Default value: undefined.

####Type: `concat_fragment`

#####`content`

Supplies the content of the fragment. **Note**: You must supply either a `content` parameter or a `source` parameter. Valid options: a string. Default value: undef.

#####`order`

Reorders your fragments within the destination file. Fragments that share the same order number are ordered by name. Valid options: a string (recommended) or an integer. Default value: '10'.

#####`source`

Specifies a file to read into the content of the fragment. **Note**: You must supply either a `content` parameter or a `source` parameter. Valid options: a string or an array, containing one or more Puppet URLs. Default value: undefined.

#####`tag`

*Required.* Specifies a unique tag to be used by concat_file to reference and collect content.

#####`target`

*Required.* Specifies the destination file of the fragment. Valid options: a string containing the title of the parent `concat_file` resource.

###Removed functionality

The following functionality existed in previous versions of the concat module, but was removed in version 2.0.0:

Parameters removed from `concat::fragment`:
* `gnu`
* `backup`
* `group`
* `mode`
* `owner`

The `concat::setup` class has also been removed.

Prior to concat version 2.0.0, if you set the `warn` parameter to a string value of 'true', 'false', 'yes', 'no', 'on', or 'off', the module translated the string to the corresponding boolean value. In concat version 2.0.0 and newer, the `warn_header` parameter treats those values the same as other strings and uses them as the content of your header message. To avoid that, pass the 'true' and 'false' values as booleans instead of strings.

##Limitations

This module has been tested on [all PE-supported platforms](https://forge.puppetlabs.com/supported#compat-matrix), and no issues have been identified.

##Development

Puppet Labs modules on the Puppet Forge are open projects, and community contributions are essential for keeping them great. We can't access the huge number of platforms and myriad of hardware, software, and deployment configurations that Puppet is intended to serve.

We want to keep it as easy as possible to contribute changes so that our modules work in your environment. There are a few guidelines that we need contributors to follow so that we can have a chance of keeping on top of things.

For more information, see our [module contribution guide.](https://docs.puppetlabs.com/forge/contributing.html)

###Contributors

Richard Pijnenburg ([@Richardp82](http://twitter.com/richardp82))

Joshua Hoblitt ([@jhoblitt](http://twitter.com/jhoblitt))

[More contributors.](https://github.com/puppetlabs/puppetlabs-concat/graphs/contributors)
