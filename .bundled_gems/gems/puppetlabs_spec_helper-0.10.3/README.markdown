Puppet Labs Spec Helper
=======================

The Short Version
-----------------

This repository is meant to provide a single source of truth for how to
initialize different Puppet versions for spec testing.

The common use case is a module such as
[stdlib](http://forge.puppetlabs.com/puppetlabs/stdlib) that works with many
versions of Puppet.  The stdlib module should require the spec helper in this
repository, which will in turn automatically figure out the version of Puppet
being tested against and perform version specific initialization.

Other "customers" that should use this module are:

 * [Facter](https://github.com/puppetlabs/facter)
 * [PuppetDB](https://github.com/puppetlabs/puppetdb)
 * [Mount Providers](https://github.com/puppetlabs/puppetlabs-mount_providers)

Usage
=====

When developing or testing modules, simply clone this repository and install the
gem it contains.

    $ git clone git://github.com/puppetlabs/puppetlabs_spec_helper.git
    $ cd puppetlabs_spec_helper
    $ rake package:gem
    $ gem install pkg/puppetlabs_spec_helper-*.gem

Add this to your project's spec\_helper.rb:

    require 'puppetlabs_spec_helper/module_spec_helper'

Add this to your project's Rakefile:

    require 'puppetlabs_spec_helper/rake_tasks'

And run the spec tests:

    $ cd $modulename
    $ rake spec

Issues
======

Please file issues against this project at the [Puppet Labs Issue
Tracker](https://tickets.puppetlabs.com/browse/MODULES)

The Long Version
----------------

Purpose of this Project
=======================

This project is intended to serve two purposes:

1. To serve as a bridge between external projects and multiple versions of puppet;
   in other words, if your project has a dependency on puppet, you shouldn't need
   to need to worry about the details of how to initialize puppet's state for
   testing, no matter what version of puppet you are testing against.
2. To provide some convenience classes / methods for doing things like creating
   tempfiles, common rspec matchers, etc.  These classes are in the puppetlabs\_spec
   directory.
3. To provide a common set of Rake tasks so that the procedure for testing modules
   is unified.

To Use this Project
===================

The most common usage scenario is that you will check out the 'master'
branch of this project from github, and install it as a rubygem.
There should be few or no cases where you would want to have any other
branch of this project besides master/HEAD.

Initializing Puppet for Testing
===============================

In most cases, your project should be able to define a spec\_helper.rb that includes
just this one simple line:

    require 'puppetlabs_spec_helper/puppet_spec_helper'

Then, as long as the gem is installed, you should be all set.

If you are using rspec-puppet for module testing, you will want to include a different
library:

    require 'puppetlabs_spec_helper/module_spec_helper'

NOTE that this is specifically for initializing Puppet's core.  If your project does
not have any dependencies on puppet and you just want to use the utility classes,
see the next section.

A number of the Puppet parser features, controlled via configuration during a
normal puppet run, can be controlled by exporting specific environment
variables for the spec run. These are:

* ``FUTURE_PARSER`` - set to "yes" to enable the [future parser](http://docs.puppetlabs.com/puppet/latest/reference/experiments_future.html),
  the equivalent of setting [parser=future](http://docs.puppetlabs.com/references/latest/configuration.html#parser)
  in puppet.conf.
* ``STRICT_VARIABLES`` - set to "yes" to enable strict variable checking,
  the equivalent of setting [strict_variables](http://docs.puppetlabs.com/references/latest/configuration.html#strictvariables)=true
  in puppet.conf.
* ``ORDERING`` - set to the desired ordering method ("title-hash", "manifest", or "random")
  to set the order of unrelated resources when applying a catalog. Leave unset for the default
  behavior, currently "random". This is equivalent to setting [ordering](http://docs.puppetlabs.com/references/latest/configuration.html#ordering)
  in puppet.conf.
* ``STRINGIFY_FACTS`` - set to "no" to enable [structured facts](http://docs.puppetlabs.com/facter/2.0/fact_overview.html#writing-structured-facts),
  otherwise leave unset to retain the current default behavior. This is equivalent to setting
  [stringify_facts=false](http://docs.puppetlabs.com/references/latest/configuration.html#stringifyfacts)
  in puppet.conf.
* ``TRUSTED_NODE_DATA`` - set to "yes" to enable [the $facts hash and trusted node data](http://docs.puppetlabs.com/puppet/latest/reference/lang_facts_and_builtin_vars.html),
  which enabled ``$facts`` and ``$trusted`` hashes. This is equivalent to setting
  [trusted_node_data=true](http://docs.puppetlabs.com/references/latest/configuration.html#trustednodedata)
  in puppet.conf.

As an example, to run spec tests with the future parser, strict variable checking,
and manifest ordering, you would:

    FUTURE_PARSER=yes STRICT_VARIABLES=yes ORDERING=manifest rake spec

Using Utility Classes
=====================
If you'd like to use the Utility classes (PuppetlabsSpec::Files,
PuppetlabsSpec::Fixtures), you just need to add this to your project's spec\_helper.rb:

    require 'puppetlabs_spec_helper/puppetlabs_spec_helper'

NOTE that the above line happens automatically if you've required
'puppetlabs\_spec\_helper/puppet\_spec\_helper', so you don't need to do both.

In either case, you'll have all of the functionality of Puppetlabs::Files,
Puppetlabs::Fixtures, etc., mixed-in to your rspec context.

Using Fixtures
==============
`puppetlabs_spec_helper` has the ability to populate the
`spec/fixtures/modules` directory with dependent modules when `rake spec` or
`rake spec_prep` is run. To do so, all required modules should be listed in a
file named `.fixtures.yml` in the root of the project.

When specifying the repo source of the fixture you have a few options as to which revision of the codebase you wish to use. 

 * repo - the url to the repo
 * scm - options include git or hg. This is an optional step as the helper code will figure out which scm is used.
   ```yaml
   scm: git
   scm: hg
   ```
 * target - the directory name to clone the repo into ie. `target: mymodule`  defaults to the repo name  (Optional)
 * ref - used to specify the tag name like version hash of commit (Optional)
   ```yaml
   ref: 1.0.0
   ref: 880fca52c
   ```
 * branch - used to specify the branch name you want to use ie. `branch: development`
 
 **Note:** ref and branch can be used together to get a specific revision on a specific branch

Fixtures Examples
-----------------
Basic fixtures that will symlink `spec/fixtures/modules/my_modules` to the
project root:

    fixtures:
      symlinks:
        my_module: "#{source_dir}"


Add `firewall` and `stdlib` as required module fixtures:

    fixtures:
      repositories:
        firewall: "git://github.com/puppetlabs/puppetlabs-firewall"
        stdlib: "git://github.com/puppetlabs/puppetlabs-stdlib"
      symlinks:
        my_module: "#{source_dir}"

Specify that the git tag `2.4.2` of `stdlib' should be checked out:

    fixtures:
      repositories:
        firewall: "git://github.com/puppetlabs/puppetlabs-firewall"
        stdlib:
          repo: "git://github.com/puppetlabs/puppetlabs-stdlib"
          ref: "2.6.0"
      symlinks:
        my_module: "#{source_dir}"

Install modules from Puppet Forge:

    fixtures:
        forge_modules:
            firewall: "puppetlabs/firewall"
            stdlib:
                repo: "puppetlabs/stdlib"
                ref: "2.6.0"


Testing Parser Functions
========================

This library provides a consistent way to create a Puppet::Parser::Scope object
suitable for use in a testing harness with the intent of testing the expected
behavior of parser functions distributed in modules.

Previously, modules would do something like this:

    describe "split()" do
      let(:scope) { Puppet::Parser::Scope.new }
      it "should split 'one;two' on ';' into [ 'one', 'two' ]" do
        scope.function_split(['one;two', ';']).should == [ 'one', 'two' ]
      end
    end

This will not work beyond Puppet 2.7 as we have changed the behavior of the
scope initializer in Puppet 3.0.  Modules should instead initialize scope
instances in a manner decoupled from the internal behavior of Puppet:

    require 'puppetlabs_spec_helper/puppetlabs_spec/puppet_internals'
    describe "split()" do
      let(:scope) { PuppetlabsSpec::PuppetInternals.scope }
      it "should split 'one;two' on ';' into [ 'one', 'two' ]" do
        scope.function_split(['one;two', ';']).should == [ 'one', 'two' ]
      end
    end

EOF
