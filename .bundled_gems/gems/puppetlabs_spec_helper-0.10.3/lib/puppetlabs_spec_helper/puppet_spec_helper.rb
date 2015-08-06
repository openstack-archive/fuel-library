require 'puppetlabs_spec_helper/puppetlabs_spec_helper'

# Don't want puppet getting the command line arguments for rake or autotest
ARGV.clear

# This is needed because we're using mocha with rspec instead of Test::Unit or MiniTest
ENV['MOCHA_OPTIONS']='skip_integration'

require 'puppet'
require 'rspec/expectations'
require 'mocha/api'

require 'pathname'
require 'tmpdir'

require 'puppetlabs_spec_helper/puppetlabs_spec/files'

######################################################################################
#                                     WARNING                                        #
######################################################################################
#
# You should probably be frightened by this file.  :)
#
# The goal of this file is to try to maximize spec-testing compatibility between
# multiple versions of various external projects (which depend on puppet core) and
# multiple versions of puppet core itself.  This is accomplished via a series
# of hacks and magical incantations that I am not particularly proud of.  However,
# after discussion it was decided that the goal of achieving compatibility was
# a very worthy one, and that isolating the hacks to one place in a non-production
# project was as good a solution as we could hope for.
#
# You may want to hold your nose before you proceed. :)
#


# This is just a utility class to allow us to isolate the various version-specific
# branches of initialization logic into methods without polluting the global namespace.#
module Puppet
  class PuppetSpecInitializer
    # This method uses the "new"/preferred approach of delegating all of the test
    # state initialization to puppet itself, via Puppet::Test::TestHelper API.  This
    # should be fairly future-proof as long as that API doesn't change, which it
    # hopefully will not need to.
    def self.initialize_via_testhelper(config)
      begin
        Puppet::Test::TestHelper.initialize
      rescue NoMethodError
        Puppet::Test::TestHelper.before_each_test
      end

      # connect rspec hooks to TestHelper methods.
      config.before :all do
        Puppet::Test::TestHelper.before_all_tests
      end

      config.after :all do
        Puppet::Test::TestHelper.after_all_tests
      end

      config.before :each do
        Puppet::Test::TestHelper.before_each_test
      end

      config.after :each do
        Puppet::Test::TestHelper.after_each_test
      end
    end

    # This method is for initializing puppet state for testing for older versions
    # of puppet that do not support the new TestHelper API.  As you can see,
    # this involves explicitly modifying global variables, directly manipulating
    # Puppet's Settings singleton object, and other fun implementation details
    # that code external to puppet should really never know about.
    def self.initialize_via_fallback_compatibility(config)
      config.before :all do
        # nothing to do for now
      end

      config.after :all do
        # nothing to do for now
      end

      config.before :each do
        # these globals are set by Application
        $puppet_application_mode = nil
        $puppet_application_name = nil

        # REVISIT: I think this conceals other bad tests, but I don't have time to
        # fully diagnose those right now.  When you read this, please come tell me
        # I suck for letting this float. --daniel 2011-04-21
        Signal.stubs(:trap)

        # Set the confdir and vardir to gibberish so that tests
        # have to be correctly mocked.
        Puppet[:confdir] = "/dev/null"
        Puppet[:vardir] = "/dev/null"

        # Avoid opening ports to the outside world
        Puppet.settings[:bindaddress] = "127.0.0.1"
      end

      config.after :each do
        Puppet.settings.clear

        Puppet::Node::Environment.clear
        Puppet::Util::Storage.clear
        Puppet::Util::ExecutionStub.reset if Puppet::Util.constants.include? "ExecutionStub"

        PuppetlabsSpec::Files.cleanup
      end
    end
  end
end



# Here we attempt to load the new TestHelper API, and print a warning if we are falling back
# to compatibility mode for older versions of puppet.
begin
  require 'puppet/test/test_helper'
rescue LoadError => err
  $stderr.puts("Warning: you appear to be using an older version of puppet; spec_helper will use fallback compatibility mode.")
end


# JJM Hack to make the stdlib tests run in Puppet 2.6 (See puppet commit cf183534)
if not Puppet.constants.include? "Test" then
  module Puppet::Test
    class LogCollector
      def initialize(logs)
        @logs = logs
      end

      def <<(value)
        @logs << value
      end
    end
  end
  Puppet::Util::Log.newdesttype :log_collector do
    match "Puppet::Test::LogCollector"

    def initialize(messages)
      @messages = messages
    end

    def handle(msg)
      @messages << msg
    end
  end
end


# And here is where we do the main rspec configuration / setup.
RSpec.configure do |config|
  config.mock_with :mocha

  # determine whether we can use the new API or not, and call the appropriate initializer method.
  if (defined?(Puppet::Test::TestHelper))
    Puppet::PuppetSpecInitializer.initialize_via_testhelper(config)
  else
    Puppet::PuppetSpecInitializer.initialize_via_fallback_compatibility(config)
  end

  # Here we do some general setup that is relevant to all initialization modes, regardless
  # of the availability of the TestHelper API.

  config.before :each do
    # Here we redirect logging away from console, because otherwise the test output will be
    #  obscured by all of the log output.
    #
    # TODO: in a more sane world, we'd move this logging redirection into our TestHelper
    #  class, so that it was not coupled with a specific testing framework (rspec in this
    #  case).  Further, it would be nicer and more portable to encapsulate the log messages
    #  into an object somewhere, rather than slapping them on an instance variable of the
    #  actual test class--which is what we are effectively doing here.
    #
    # However, because there are over 1300 tests that are written to expect
    #  this instance variable to be available--we can't easily solve this problem right now.
    @logs = []
    Puppet::Util::Log.newdestination(Puppet::Test::LogCollector.new(@logs))

    @log_level = Puppet::Util::Log.level
  end

  config.after :each do
    # clean up after the logging changes that we made before each test.

    # TODO: this should be abstracted in the future--see comments above the '@logs' block in the
    #  "before" code above.
    @logs.clear
    Puppet::Util::Log.close_all
    Puppet::Util::Log.level = @log_level
  end

end
