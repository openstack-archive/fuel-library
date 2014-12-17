Puppet FileMapper
=================

Synopsis
--------

Map files to resources and back with this handy dandy mixin!

Documentation is available at [http://adrienthebo.github.com/puppet-filemapper/](http://adrienthebo.github.com/puppet-filemapper/)

Travis Test status: [![Build Status](https://travis-ci.org/adrienthebo/puppet-filemapper.png)](https://travis-ci.org/adrienthebo/puppet-filemapper)

Description
-----------

Things that are harder than they should be:

  * Acquiring a pet monkey
  * Getting anywhere in Los Angeles
  * Understanding the ParsedFile provider
  * Writing Puppet providers that directly manipulate files

The solution for this is to completely bypass parsing in any sort of base
provider, and delegate the role of parsing and generating to including classes.

You figure out how to parse and write the file, and this will do the rest.

Synopsis of implementation requirements
---------------------------------------

Providers using the Filemapper extension need to implement the following
methods.

### `self.target_files`

This should return an array of filenames specifying which files should be
prefetched.

### `self.parse_file(filename, file_contents)`

This should take two values, a string containing the file name, and a string
containing the contents of the file. It should return an array of hashes,
where each hash represents {property => value} pairs.

### `select_file`

This is a provider instance method. It should return a string containing the
filename that the provider should be flushed to.

### `self.format_file(filename, providers)`

This should take two values, a string containing the file name to be flushed,
and an array of providers that should be flushed to this file. It should return
a string containing the contents of the file to be written.

Synopsis of optional implementation hooks
-----------------------------------------

### `self.pre_flush_hook(filename)` and `self.post_flush_hook(filename)`

These methods can be implemented to add behavior right before and right after
filesystem operations. Both methods take a single argument, a string
containing the name of the file to be flushed.

If `self.pre_flush_hook` raises an exception, the flush will not occur and the
provider will be marked as failed and will refuse to perform any more flushes.
If some sort of critical error occurred, this can force the provider to error
out before it starts stomping on files.

`self.post_flush_hook` is guaranteed to run after any filesystem operations
occur. This can be used for recovery if something goes wrong during the flush.
If this method raises an exception, the provider will be marked as failed and
will refuse to perform any more flushes.

Removing empty files
--------------------

If a file is empty, it's often reasonable to just delete it. The Filemapper
mixin implements `attr_accessor :unlink_empty_files`. If that value is set to
true, then if `self.format_file` returns the empty string then the file will be
deleted from the file system.

How it works
------------

[transaction]: http://somethingsinistral.net/blog/reading-puppet-the-transaction/

The Filemapper extension takes advantage of hooks within the
[Transaction][transaction] to reduce the number of reads and writes needed to
perform operations.

### prefetching

When a catalog is being applied, providers can define the `prefetch` method to
load all resources before runtime. The Filemapper extension uses this method to
preemptively read all files that the provider requires, and generates and stores
the state of the requested resources. This means that if you have a few thousand
resources in 20 files, you only need to do 20 reads for the entire Puppet run.

### post-evaluation flushing

When resources are normally evaluated, each time a property is synchronized it's
expected that an action will be run right then. The Filemapper extension instead
records all the requested changes and defers operating on them. When the
resource is finished, it will be flushed, at which time all of the requested
changes will be applied in one pass. Given a resource with 10 properties, all of
which are out of sync, the file will be written only once. If no properties are
out of sync, the file will be untouched.

To ensure that the system state matches what Puppet thinks is going on, any file
that has changed resources will be re-written after each resource is flushed.
That means that if you have 20 resources out of sync, that file will have to be
written 20 times. While it's technically possible to write the file in a single
pass, this means that some resources will be applied either early or late, which
utterly smashes POLA.

### Use on the command line

The Filemapper extension implements the `instances` method, which means that you
can use the `puppet resource` command to interact with the associated provider
without having to perform a full blown Puppet run.

### Selecting files to load

In order to provide prefetching and `puppet resource` in a clean manner, the
Filemapper extension has to have a full list of what files to read. Implementing
classes need to implement the `target_files` method which returns a list of
files to read. The implementation is entirely up to the implementing class; it
can return a single file every time, such as "/etc/inittab", or it can generate
that information on the fly, by returning `Dir["/etc/sysconfig/network/ifcfg-*"]`.
Basically, files that will be used as a source of data can be as complex or
simple as you need.

### Writing back files

In a similar vein, resources can be written back to files in whatever method you
need. Implementing classes need to implement the *instance method* `#select_file`
so that when that resource is changed, the correct file is modified.

### Parsing

When parsing a file, the implementing class needs to implement the `parse_file`
method. It will get the name of the file being parsed as well as the contents.
It can parse this file in whatever manner needed, and should return an array of
any provider instances generated. If the file only contains a single provider
instance, then just wrap that instance in an array.

### Writing

Whenever a file is marked as dirty, that is a resource associated with that file
has changed, the `format_file` method will be called. The implementing class
needs to implement a method that takes the filename and an array of provider
instances associated with that file, and return a string. The method needs to
determine how that file should be written to disk and then return the contents.
This can be as complex as needed.

Under no conditions should implementing classes modify any files directly. No,
seriously, don't do it. The Filemapper extension uses the built in methods for
modifying files, which will back up changed files to the filebucket. This is for
your own safety, so if you bypass this then you are on your own.

### Storing state outside of resources

It's more or less expected that there will be no state outside of the provider
instances, but there are plenty of cases where this could be the case. For
instance, if one wanted to preserve the comments in a file but didn't directly
associate them with resource attributes, the `parse_file` method can store data
in an instance variable, such as `@comments = my_list_of_comments`. When
formatting the file, the implementing class can read the `@comments` variable
and re-add that data to the content that will be written back.

Basically, you can store whatever data you need in these methods and pass things
around to maintain more complex state.

Using this sort of operation of reading outside state, you can theoretically
have multiple Filemapper extensions that work on shared files. By communicating
the state between them, you can manage multiple different resources in one file.
**HOWEVER**, this will require careful communication, so don't take this sort of
thing lightly. However, I don't thing that anything else in Puppet can provide
this sort of behavior. YMMV.

### Why a mixin?

While the ParsedFile provider is supposed to be inherited, this class is a mixin
and needs to be included. This is done because the Filemapper extension only
*adds* behavior, and isn't really an object or entity in its own right. This way
you can use the Filemapper extension while inheriting from something like the
Puppet::Provider::Package provider.

The Backstory
-------------

Managing Unix-ish systems generally means dealing with one of two things:

  1. Processes - starting them, stopping them, monitoring them, etc.
  1. Files - Creating them, editing, deleting them, specifying permissions, etc.

Puppet has pretty good support in the provider layer for running commands, but
the file manipulation layer has been lacking. The long-standing approach for
manipulating files has been to select one of the following, and hope for the best.

### Shipping flat files to the client

Using the `File` resource to ship flat files is a really common solution, and
it's very easy. It also has the finesse of a brick thrown through a window.
There is very little customizability here, aside from the array notation for
[specifying the `source` field](http://docs.puppetlabs.com/references/latest/type.html#file).

### Using ERB templates to customize files

The File resource can also take a content field, to which you can pass the
output of a template. This allows more sophistication, but not much. It also
adds more of a burden to your master; template rendering happens on the master
and if you're doing really crazy number crunching then this pain will be
centralized.

### Using Augeas

Augeas is a very powerful tool that allows you to manipulate files, and the
`Augeas` type allows you to harness this inside of Puppet. However, it has a
rather byzantine syntax, and is dependent on lenses being available.

### Sed

I personally love sed, but sed a file configuration management tool is not.

### Using the ParsedFile provider

[parsedfile]: https://github.com/puppetlabs/puppet/blob/2.7.19/lib/puppet/provider/parsedfile.rb "Puppet 2.7.19 - ParsedFile provider"

Puppet has a provider extension called the [ParsedFile provider][parsedfile]
that's used to manipulate text like crontabs and so forth. It also uses a number
of advanced features in puppet, which makes it quite powerful. However, it's
incredibly complex, tightly coupled with the FileParsing utility language, has
tons of obscure and undocumented hooks that are the only way to do complex
operations, and is entirely record based which makes it unsuitable for managing
files that have complex structure. While it has basic support for managing
multiple files, *basic* is the indicative word.

- - -

The Filemapper extension has been designed as a lower level alternative
to the ParsedFile.

Examples
--------

[puppet-network]: https://github.com/adrienthebo/puppet-network

The Filemapper extension was largely extracted out of the [puppet-network][puppet-network]
module. That code base should display the weird edge cases that this extension
handles.
