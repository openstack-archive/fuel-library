#inifile

[![Build Status](https://travis-ci.org/puppetlabs/puppetlabs-inifile.png?branch=master)](https://travis-ci.org/puppetlabs/puppetlabs-inifile)

####Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with inifile module](#setup)
    * [Beginning with inifile](#beginning-with-inifile)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

##Overview

The inifile module lets Puppet manage settings stored in INI-style configuration files.

##Module Description

Many applications use INI-style configuration files to store their settings. This module supplies two custom resource types to let you manage those settings through Puppet.

##Setup

###Beginning with inifile


To manage a single setting in an INI file, add the `ini_setting` type to a class:

~~~
ini_setting { "sample setting":
  ensure  => present,
  path    => '/tmp/foo.ini',
  section => 'bar',
  setting => 'baz',
  value   => 'quux',
}
~~~

##Usage


The inifile module tries hard not to manipulate your file any more than it needs to. In most cases, it doesn't affect the original whitespace, comments, ordering, etc.

 * Supports comments starting with either '#' or ';'.
 * Supports either whitespace or no whitespace around '='.
 * Adds any missing sections to the INI file.

###Manage multiple values in a setting

Use the `ini_subsetting` type:

~~~
JAVA_ARGS="-Xmx192m -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/var/log/pe-puppetdb/puppetdb-oom.hprof "

ini_subsetting {'sample subsetting':
  ensure            => present,
  section           => '',
  key_val_separator => '=',
  path              => '/etc/default/pe-puppetdb',
  setting           => 'JAVA_ARGS',
  subsetting        => '-Xmx',
  value             => '512m',
}
~~~

###Use a non-standard section header

~~~
default:
   minage = 1
   maxage = 13

ini_setting { 'default minage':
  ensure         => present,
  path           => '/etc/security/users',
  section        => 'default',
  setting        => 'minage',
  value          => '1',
  section_prefix => '',
  section_suffix => ':',
}
~~~

###Implement child providers


You might want to create child providers that inherit the `ini_setting` provider, for one or both of these purposes:

 * Make a custom resource to manage an application that stores its settings in INI files, without recreating the code to manage the files themselves.

 * [Purge all unmanaged settings](https://docs.puppetlabs.com/references/latest/type.html#resources-attribute-purge) from a managed INI file.

To implement child providers, first specify a custom type. Have it implement a namevar called `name` and a property called `value`:

~~~
#my_module/lib/puppet/type/glance_api_config.rb
Puppet::Type.newtype(:glance_api_config) do
  ensurable
  newparam(:name, :namevar => true) do
    desc 'Section/setting name to manage from glance-api.conf'
    # namevar should be of the form section/setting
    newvalues(/\S+\/\S+/)
  end
  newproperty(:value) do
    desc 'The value of the setting to define'
    munge do |v|
      v.to_s.strip
    end
  end
end
~~~

Your type also needs a provider that uses the `ini_setting` provider as its parent:

~~~
# my_module/lib/puppet/provider/glance_api_config/ini_setting.rb
Puppet::Type.type(:glance_api_config).provide(
  :ini_setting,
  # set ini_setting as the parent provider
  :parent => Puppet::Type.type(:ini_setting).provider(:ruby)
) do
  # implement section as the first part of the namevar
  def section
    resource[:name].split('/', 2).first
  end
  def setting
    # implement setting as the second part of the namevar
    resource[:name].split('/', 2).last
  end
  # hard code the file path (this allows purging)
  def self.file_path
    '/etc/glance/glance-api.conf'
  end
end
~~~

Now the settings in /etc/glance/glance-api.conf file can be managed as individual resources:

~~~
glance_api_config { 'HEADER/important_config':
  value => 'secret_value',
}
~~~

If you've implemented self.file_path, you can have Puppet purge the file of all lines that aren't implemented as Puppet resources:

~~~
resources { 'glance_api_config'
  purge => true,
}
~~~

##Reference

###Public Types

 * [`ini_setting`](#type-ini_setting)

 * [`ini_subsetting`](#type-ini_subsetting)

### Type: ini_setting

Manages a setting within an INI file.

#### Parameters

##### `ensure`

Determines whether the specified setting should exist. Valid options: 'present' and 'absent'. Default value: 'present'.

##### `key_val_separator`

*Optional.* Specifies a string to use between each setting name and value (e.g., to determine whether the separator includes whitespace). Valid options: a string. Default value: ' = '.

##### `name`

*Optional.* Specifies an arbitrary name to identify the resource. Valid options: a string. Default value: the title of your declared resource.

##### `path`

*Required.* Specifies an INI file containing the setting to manage. Valid options: a string containing an absolute path.

##### `section`

*Required.* Designates a section of the specified INI file containing the setting to manage. To manage a global setting (at the beginning of the file, before any named sections) enter "". Valid options: a string.

##### `setting`

*Optional.* Designates a section of the specified INI file containing the setting to manage. To manage a global setting (at the beginning of the file, before any named sections) enter "". Defaults to "". Valid options: a string.

##### `value`

*Optional.* Supplies a value for the specified setting. Valid options: a string. Default value: undefined.

##### `section_prefix`

*Optional.*  Designates the string that will appear before the section's name.  Default value: "["

##### `section_suffix`

*Optional.*  Designates the string that will appear after the section's name.  Default value: "]"

**NOTE:** The way this type finds all sections in the file is by looking for lines like `${section_prefix}${title}${section_suffix}`

### Type: ini_subsetting


Manages multiple values within the same INI setting.

#### Parameters

##### `ensure`

Specifies whether the subsetting should be present. Valid options: 'present' and 'absent'. Default value: 'present'.

##### `key_val_separator`

*Optional.* Specifies a string to use between subsetting name and value (e.g., to determine whether the separator includes whitespace). Valid options: a string. Default value: ' = '.

##### `path`

*Required.* Specifies an INI file containing the subsetting to manage. Valid options: a string containing an absolute path.

##### `quote_char`

*Optional.* The character used to quote the entire value of the setting. Valid values are '', '"', and "'". Defaults to ''. Valid options: '', '"' and "'". Default value: ''.

##### `section`

*Optional.* Designates a section of the specified INI file containing the setting to manage. To manage a global setting (at the beginning of the file, before any named sections) enter "". Defaults to "". Valid options: a string.

##### `setting`

*Required.* Designates a setting within the specified section containing the subsetting to manage. Valid options: a string.

##### `subsetting`

*Required.* Designates a subsetting to manage within the specified setting. Valid options: a string.


##### `subsetting_separator`

*Optional.* Specifies a string to use between subsettings. Valid options: a string. Default value: " ".

##### `value`

*Optional.* Supplies a value for the specified subsetting. Valid options: a string. Default value: undefined.

##Limitations

This module has been tested on [all PE-supported platforms](https://forge.puppetlabs.com/supported#compat-matrix), and no issues have been identified. Additionally, it is tested (but not supported) on Windows 7 and Mac OS X 10.9.

##Development

#Development

Puppet Labs modules on the Puppet Forge are open projects, and community contributions are essential for keeping them great. We can't access the huge number of platforms and myriad of hardware, software, and deployment configurations that Puppet is intended to serve.

We want to keep it as easy as possible to contribute changes so that our modules work in your environment. There are a few guidelines that we need contributors to follow so that we can have a chance of keeping on top of things.

For more information, see our [module contribution guide.](https://docs.puppetlabs.com/forge/contributing.html)

###Contributors

To see who's already involved, see the [list of contributors.](https://github.com/puppetlabs/puppetlabs-inifile/graphs/contributors)
