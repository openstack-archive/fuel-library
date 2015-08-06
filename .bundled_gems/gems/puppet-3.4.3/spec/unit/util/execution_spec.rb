#! /usr/bin/env ruby
require 'spec_helper'

describe Puppet::Util::Execution do
  include Puppet::Util::Execution
  # utility method to help deal with some windows vs. unix differences
  def process_status(exitstatus)
    return exitstatus if Puppet.features.microsoft_windows?

    stub('child_status', :exitstatus => exitstatus)
  end

  # utility methods to help us test some private methods without being quite so verbose
  def call_exec_posix(command, arguments, stdin, stdout, stderr)
    Puppet::Util::Execution.send(:execute_posix, command, arguments, stdin, stdout, stderr)
  end
  def call_exec_windows(command, arguments, stdin, stdout, stderr)
    Puppet::Util::Execution.send(:execute_windows, command, arguments, stdin, stdout, stderr)
  end

  describe "execution methods" do
    let(:pid) { 5501 }
    let(:process_handle) { 0xDEADBEEF }
    let(:thread_handle) { 0xCAFEBEEF }
    let(:proc_info_stub) { stub 'processinfo', :process_handle => process_handle, :thread_handle => thread_handle, :process_id => pid}
    let(:null_file) { Puppet.features.microsoft_windows? ? 'NUL' : '/dev/null' }

    def stub_process_wait(exitstatus)
      if Puppet.features.microsoft_windows?
        Puppet::Util::Windows::Process.stubs(:wait_process).with(process_handle).returns(exitstatus)
        Process.stubs(:CloseHandle).with(process_handle)
        Process.stubs(:CloseHandle).with(thread_handle)
      else
        Process.stubs(:waitpid2).with(pid).returns([pid, stub('child_status', :exitstatus => exitstatus)])
      end
    end

    describe "#execute_posix (stubs)", :unless => Puppet.features.microsoft_windows? do
      before :each do
        # Most of the things this method does are bad to do during specs. :/
        Kernel.stubs(:fork).returns(pid).yields
        Process.stubs(:setsid)
        Kernel.stubs(:exec)
        Puppet::Util::SUIDManager.stubs(:change_user)
        Puppet::Util::SUIDManager.stubs(:change_group)

        # ensure that we don't really close anything!
        (0..256).each {|n| IO.stubs(:new) }

        $stdin.stubs(:reopen)
        $stdout.stubs(:reopen)
        $stderr.stubs(:reopen)

        @stdin  = File.open(null_file, 'r')
        @stdout = Tempfile.new('stdout')
        @stderr = File.open(null_file, 'w')

        # there is a danger here that ENV will be modified by exec_posix.  Normally it would only affect the ENV
        #  of a forked process, but here, we're stubbing Kernel.fork, so the method has the ability to override the
        #  "real" ENV.  To guard against this, we'll capture a snapshot of ENV before each test.
        @saved_env = ENV.to_hash

        # Now, we're going to effectively "mock" the magic ruby 'ENV' variable by creating a local definition of it
        #  inside of the module we're testing.
        Puppet::Util::Execution::ENV = {}
      end

      after :each do
        # And here we remove our "mock" version of 'ENV', which will allow us to validate that the real ENV has been
        #  left unharmed.
        Puppet::Util::Execution.send(:remove_const, :ENV)

        # capture the current environment and make sure it's the same as it was before the test
        cur_env = ENV.to_hash

        # we will get some fairly useless output if we just use the raw == operator on the hashes here, so we'll
        #  be a bit more explicit and laborious in the name of making the error more useful...
        @saved_env.each_pair { |key,val| cur_env[key].should == val }
        (cur_env.keys - @saved_env.keys).should == []

      end


      it "should fork a child process to execute the command" do
        Kernel.expects(:fork).returns(pid).yields
        Kernel.expects(:exec).with('test command')

        call_exec_posix('test command', {}, @stdin, @stdout, @stderr)
      end

      it "should start a new session group" do
        Process.expects(:setsid)

        call_exec_posix('test command', {}, @stdin, @stdout, @stderr)
      end

      it "should permanently change to the correct user and group if specified" do
        Puppet::Util::SUIDManager.expects(:change_group).with(55, true)
        Puppet::Util::SUIDManager.expects(:change_user).with(50, true)

        call_exec_posix('test command', {:uid => 50, :gid => 55}, @stdin, @stdout, @stderr)
      end

      it "should exit failure if there is a problem execing the command" do
        Kernel.expects(:exec).with('test command').raises("failed to execute!")
        Puppet::Util::Execution.stubs(:puts)
        Puppet::Util::Execution.expects(:exit!).with(1)

        call_exec_posix('test command', {}, @stdin, @stdout, @stderr)
      end

      it "should properly execute commands specified as arrays" do
        Kernel.expects(:exec).with('test command', 'with', 'arguments')

        call_exec_posix(['test command', 'with', 'arguments'], {:uid => 50, :gid => 55}, @stdin, @stdout, @stderr)
      end

      it "should properly execute string commands with embedded newlines" do
        Kernel.expects(:exec).with("/bin/echo 'foo' ; \n /bin/echo 'bar' ;")

        call_exec_posix("/bin/echo 'foo' ; \n /bin/echo 'bar' ;", {:uid => 50, :gid => 55}, @stdin, @stdout, @stderr)
      end

      it "should return the pid of the child process" do
        call_exec_posix('test command', {}, @stdin, @stdout, @stderr).should == pid
      end
    end

    describe "#execute_windows (stubs)", :if => Puppet.features.microsoft_windows? do
      before :each do
        Process.stubs(:create).returns(proc_info_stub)
        stub_process_wait(0)

        @stdin  = File.open(null_file, 'r')
        @stdout = Tempfile.new('stdout')
        @stderr = File.open(null_file, 'w')
      end

      it "should create a new process for the command" do
        Process.expects(:create).with(
          :command_line => "test command",
          :startup_info => {:stdin => @stdin, :stdout => @stdout, :stderr => @stderr},
          :close_handles => false
        ).returns(proc_info_stub)

        call_exec_windows('test command', {}, @stdin, @stdout, @stderr)
      end

      it "should return the process info of the child process" do
        call_exec_windows('test command', {}, @stdin, @stdout, @stderr).should == proc_info_stub
      end

      it "should quote arguments containing spaces if command is specified as an array" do
        Process.expects(:create).with do |args|
          args[:command_line] == '"test command" with some "arguments \"with spaces"'
        end.returns(proc_info_stub)

        call_exec_windows(['test command', 'with', 'some', 'arguments "with spaces'], {}, @stdin, @stdout, @stderr)
      end
    end

    describe "#execute (stubs)" do
      before :each do
        stub_process_wait(0)
      end

      describe "when an execution stub is specified" do
        before :each do
          Puppet::Util::ExecutionStub.set do |command,args,stdin,stdout,stderr|
            "execution stub output"
          end
        end

        it "should call the block on the stub" do
          Puppet::Util::Execution.execute("/usr/bin/run_my_execute_stub").should == "execution stub output"
        end

        it "should not actually execute anything" do
          Puppet::Util::Execution.expects(:execute_posix).never
          Puppet::Util::Execution.expects(:execute_windows).never

          Puppet::Util::Execution.execute("/usr/bin/run_my_execute_stub")
        end
      end

      describe "when setting up input and output files" do
        include PuppetSpec::Files
        let(:executor) { Puppet.features.microsoft_windows? ? 'execute_windows' : 'execute_posix' }
        let(:rval) { Puppet.features.microsoft_windows? ? proc_info_stub : pid }

        before :each do
          Puppet::Util::Execution.stubs(:wait_for_output)
        end

        it "should set stdin to the stdinfile if specified" do
          input = tmpfile('stdin')
          FileUtils.touch(input)

          Puppet::Util::Execution.expects(executor).with do |_,_,stdin,_,_|
            stdin.path == input
          end.returns(rval)

          Puppet::Util::Execution.execute('test command', :stdinfile => input)
        end

        it "should set stdin to the null file if not specified" do
          Puppet::Util::Execution.expects(executor).with do |_,_,stdin,_,_|
            stdin.path == null_file
          end.returns(rval)

          Puppet::Util::Execution.execute('test command')
        end

        describe "when squelch is set" do
          it "should set stdout and stderr to the null file" do
            Puppet::Util::Execution.expects(executor).with do |_,_,_,stdout,stderr|
              stdout.path == null_file and stderr.path == null_file
            end.returns(rval)

            Puppet::Util::Execution.execute('test command', :squelch => true)
          end
        end

        describe "when squelch is not set" do
          it "should set stdout to a temporary output file" do
            outfile = Tempfile.new('stdout')
            Tempfile.stubs(:new).returns(outfile)

            Puppet::Util::Execution.expects(executor).with do |_,_,_,stdout,_|
              stdout.path == outfile.path
            end.returns(rval)

            Puppet::Util::Execution.execute('test command', :squelch => false)
          end

          it "should set stderr to the same file as stdout if combine is true" do
            outfile = Tempfile.new('stdout')
            Tempfile.stubs(:new).returns(outfile)

            Puppet::Util::Execution.expects(executor).with do |_,_,_,stdout,stderr|
              stdout.path == outfile.path and stderr.path == outfile.path
            end.returns(rval)

            Puppet::Util::Execution.execute('test command', :squelch => false, :combine => true)
          end

          it "should set stderr to the null device if combine is false" do
            outfile = Tempfile.new('stdout')
            Tempfile.stubs(:new).returns(outfile)

            Puppet::Util::Execution.expects(executor).with do |_,_,_,stdout,stderr|
              stdout.path == outfile.path and stderr.path == null_file
            end.returns(rval)

            Puppet::Util::Execution.execute('test command', :squelch => false, :combine => false)
          end

          it "should combine stdout and stderr if combine is true" do
            outfile = Tempfile.new('stdout')
            Tempfile.stubs(:new).returns(outfile)

            Puppet::Util::Execution.expects(executor).with do |_,_,_,stdout,stderr|
              stdout.path == outfile.path and stderr.path == outfile.path
            end.returns(rval)

            Puppet::Util::Execution.execute('test command', :combine => true)
          end

          it "should default combine to true when no options are specified" do
            outfile = Tempfile.new('stdout')
            Tempfile.stubs(:new).returns(outfile)

            Puppet::Util::Execution.expects(executor).with do |_,_,_,stdout,stderr|
              stdout.path == outfile.path and stderr.path == outfile.path
            end.returns(rval)

            Puppet::Util::Execution.execute('test command')
          end

          it "should default combine to false when options are specified, but combine is not" do
            outfile = Tempfile.new('stdout')
            Tempfile.stubs(:new).returns(outfile)

            Puppet::Util::Execution.expects(executor).with do |_,_,_,stdout,stderr|
              stdout.path == outfile.path and stderr.path == null_file
            end.returns(rval)

            Puppet::Util::Execution.execute('test command', :failonfail => false)
          end

          it "should default combine to false when an empty hash of options is specified" do
            outfile = Tempfile.new('stdout')
            Tempfile.stubs(:new).returns(outfile)

            Puppet::Util::Execution.expects(executor).with do |_,_,_,stdout,stderr|
              stdout.path == outfile.path and stderr.path == null_file
            end.returns(rval)

            Puppet::Util::Execution.execute('test command', {})
          end
        end
      end

      describe "on Windows", :if => Puppet.features.microsoft_windows? do
        it "should always close the process and thread handles" do
          Puppet::Util::Execution.stubs(:execute_windows).returns(proc_info_stub)

          Puppet::Util::Windows::Process.expects(:wait_process).with(process_handle).raises('whatever')
          Puppet::Util::Windows::Process.expects(:CloseHandle).with(thread_handle)
          Puppet::Util::Windows::Process.expects(:CloseHandle).with(process_handle)

          expect { Puppet::Util::Execution.execute('test command') }.to raise_error(RuntimeError)
        end

        it "should return the correct exit status even when exit status is greater than 256" do
          real_exit_status = 3010

          Puppet::Util::Execution.stubs(:execute_windows).returns(proc_info_stub)
          stub_process_wait(real_exit_status)
          $CHILD_STATUS.stubs(:exitstatus).returns(real_exit_status % 256) # The exitstatus is changed to be mod 256 so that ruby can fit it into 8 bits.

          Puppet::Util::Execution.execute('test command', :failonfail => false).exitstatus.should == real_exit_status
        end
      end
    end

    describe "#execute (posix locale)", :unless => Puppet.features.microsoft_windows?  do

      before :each do
        # there is a danger here that ENV will be modified by exec_posix.  Normally it would only affect the ENV
        #  of a forked process, but, in some of the previous tests in this file we're stubbing Kernel.fork., which could
        #  allow the method to override the "real" ENV.  This shouldn't be a problem for these tests because they are
        #  not stubbing Kernel.fork, but, better safe than sorry... so, to guard against this, we'll capture a snapshot
        #  of ENV before each test.
        @saved_env = ENV.to_hash
      end

      after :each do
        # capture the current environment and make sure it's the same as it was before the test
        cur_env = ENV.to_hash
        # we will get some fairly useless output if we just use the raw == operator on the hashes here, so we'll
        #  be a bit more explicit and laborious in the name of making the error more useful...
        @saved_env.each_pair { |key,val| cur_env[key].should == val }
        (cur_env.keys - @saved_env.keys).should == []
      end


      # build up a printf-style string that contains a command to get the value of an environment variable
      # from the operating system.  We can substitute into this with the names of the desired environment variables later.
      get_env_var_cmd = 'echo $%s'

      # a sentinel value that we can use to emulate what locale environment variables might be set to on an international
      # system.
      lang_sentinel_value = "en_US.UTF-8"
      # a temporary hash that contains sentinel values for each of the locale environment variables that we override in
      # "execute"
      locale_sentinel_env = {}
      Puppet::Util::POSIX::LOCALE_ENV_VARS.each { |var| locale_sentinel_env[var] = lang_sentinel_value }

      it "should override the locale environment variables when :override_locale is not set (defaults to true)" do
        # temporarily override the locale environment vars with a sentinel value, so that we can confirm that
        # execute is actually setting them.
        Puppet::Util.withenv(locale_sentinel_env) do
          Puppet::Util::POSIX::LOCALE_ENV_VARS.each do |var|
            # we expect that all of the POSIX vars will have been cleared except for LANG and LC_ALL
            expected_value = (['LANG', 'LC_ALL'].include?(var)) ? "C" : ""
            Puppet::Util::execute(get_env_var_cmd % var).strip.should == expected_value
          end
        end
      end

      it "should override the LANG environment variable when :override_locale is set to true" do
        # temporarily override the locale environment vars with a sentinel value, so that we can confirm that
        # execute is actually setting them.
        Puppet::Util.withenv(locale_sentinel_env) do
          Puppet::Util::POSIX::LOCALE_ENV_VARS.each do |var|
            # we expect that all of the POSIX vars will have been cleared except for LANG and LC_ALL
            expected_value = (['LANG', 'LC_ALL'].include?(var)) ? "C" : ""
            Puppet::Util::execute(get_env_var_cmd % var, {:override_locale => true}).strip.should == expected_value
          end
        end
      end

      it "should *not* override the LANG environment variable when :override_locale is set to false" do
        # temporarily override the locale environment vars with a sentinel value, so that we can confirm that
        # execute is not setting them.
        Puppet::Util.withenv(locale_sentinel_env) do
          Puppet::Util::POSIX::LOCALE_ENV_VARS.each do |var|
            Puppet::Util::execute(get_env_var_cmd % var, {:override_locale => false}).strip.should == lang_sentinel_value
          end
        end
      end

      it "should have restored the LANG and locale environment variables after execution" do
        # we'll do this once without any sentinel values, to give us a little more test coverage
        orig_env_vals = {}
        Puppet::Util::POSIX::LOCALE_ENV_VARS.each do |var|
          orig_env_vals[var] = ENV[var]
        end
        # now we can really execute any command--doesn't matter what it is...
        Puppet::Util::execute(get_env_var_cmd % 'anything', {:override_locale => true})
        # now we check and make sure the original environment was restored
        Puppet::Util::POSIX::LOCALE_ENV_VARS.each do |var|
          ENV[var].should == orig_env_vals[var]
        end

        # now, once more... but with our sentinel values
        Puppet::Util.withenv(locale_sentinel_env) do
          # now we can really execute any command--doesn't matter what it is...
          Puppet::Util::execute(get_env_var_cmd % 'anything', {:override_locale => true})
          # now we check and make sure the original environment was restored
          Puppet::Util::POSIX::LOCALE_ENV_VARS.each do |var|
            ENV[var].should == locale_sentinel_env[var]
          end
        end

      end
    end

    describe "#execute (posix user env vars)", :unless => Puppet.features.microsoft_windows?  do
      # build up a printf-style string that contains a command to get the value of an environment variable
      # from the operating system.  We can substitute into this with the names of the desired environment variables later.
      get_env_var_cmd = 'echo $%s'

      # a sentinel value that we can use to emulate what locale environment variables might be set to on an international
      # system.
      user_sentinel_value = "Abracadabra"
      # a temporary hash that contains sentinel values for each of the locale environment variables that we override in
      # "execute"
      user_sentinel_env = {}
      Puppet::Util::POSIX::USER_ENV_VARS.each { |var| user_sentinel_env[var] = user_sentinel_value }

      it "should unset user-related environment vars during execution" do
        # first we set up a temporary execution environment with sentinel values for the user-related environment vars
        # that we care about.
        Puppet::Util.withenv(user_sentinel_env) do
          # with this environment, we loop over the vars in question
          Puppet::Util::POSIX::USER_ENV_VARS.each do |var|
            # ensure that our temporary environment is set up as we expect
            ENV[var].should == user_sentinel_env[var]

            # run an "exec" via the provider and ensure that it unsets the vars
            Puppet::Util::execute(get_env_var_cmd % var).strip.should == ""

            # ensure that after the exec, our temporary env is still intact
            ENV[var].should == user_sentinel_env[var]
          end

        end
      end

      it "should have restored the user-related environment variables after execution" do
        # we'll do this once without any sentinel values, to give us a little more test coverage
        orig_env_vals = {}
        Puppet::Util::POSIX::USER_ENV_VARS.each do |var|
          orig_env_vals[var] = ENV[var]
        end
        # now we can really execute any command--doesn't matter what it is...
        Puppet::Util::execute(get_env_var_cmd % 'anything')
        # now we check and make sure the original environment was restored
        Puppet::Util::POSIX::USER_ENV_VARS.each do |var|
          ENV[var].should == orig_env_vals[var]
        end

        # now, once more... but with our sentinel values
        Puppet::Util.withenv(user_sentinel_env) do
          # now we can really execute any command--doesn't matter what it is...
          Puppet::Util::execute(get_env_var_cmd % 'anything')
          # now we check and make sure the original environment was restored
          Puppet::Util::POSIX::USER_ENV_VARS.each do |var|
            ENV[var].should == user_sentinel_env[var]
          end
        end

      end
    end

    describe "after execution" do
      before :each do
        stub_process_wait(0)

        if Puppet.features.microsoft_windows?
          Puppet::Util::Execution.stubs(:execute_windows).returns(proc_info_stub)
        else
          Puppet::Util::Execution.stubs(:execute_posix).returns(pid)
        end
      end

      it "should wait for the child process to exit" do
        Puppet::Util::Execution.stubs(:wait_for_output)

        Puppet::Util::Execution.execute('test command')
      end

      it "should close the stdin/stdout/stderr files used by the child" do
        stdin = mock 'file', :close
        stdout = mock 'file', :close
        stderr = mock 'file', :close

        File.expects(:open).
            times(3).
            returns(stdin).
            then.returns(stdout).
            then.returns(stderr)

        Puppet::Util::Execution.execute('test command', {:squelch => true, :combine => false})
      end

      it "should read and return the output if squelch is false" do
        stdout = Tempfile.new('test')
        Tempfile.stubs(:new).returns(stdout)
        stdout.write("My expected command output")

        Puppet::Util::Execution.execute('test command').should == "My expected command output"
      end

      it "should not read the output if squelch is true" do
        stdout = Tempfile.new('test')
        Tempfile.stubs(:new).returns(stdout)
        stdout.write("My expected command output")

        Puppet::Util::Execution.execute('test command', :squelch => true).should == ''
      end

      it "should delete the file used for output if squelch is false" do
        stdout = Tempfile.new('test')
        path = stdout.path
        Tempfile.stubs(:new).returns(stdout)

        Puppet::Util::Execution.execute('test command')

        Puppet::FileSystem::File.exist?(path).should be_false
      end

      it "should not raise an error if the file is open" do
        stdout = Tempfile.new('test')
        Tempfile.stubs(:new).returns(stdout)
        file = File.new(stdout.path, 'r')

        Puppet::Util.execute('test command')
      end

      it "should raise an error if failonfail is true and the child failed" do
        stub_process_wait(1)

        expect {
          subject.execute('fail command', :failonfail => true)
        }.to raise_error(Puppet::ExecutionFailure, /Execution of 'fail command' returned 1/)
      end

      it "should not raise an error if failonfail is false and the child failed" do
        stub_process_wait(1)

        subject.execute('fail command', :failonfail => false)
      end

      it "should not raise an error if failonfail is true and the child succeeded" do
        stub_process_wait(0)

        subject.execute('fail command', :failonfail => true)
      end

      it "should not raise an error if failonfail is false and the child succeeded" do
        stub_process_wait(0)

        subject.execute('fail command', :failonfail => false)
      end

      it "should default failonfail to true when no options are specified" do
        stub_process_wait(1)

        expect {
          subject.execute('fail command')
        }.to raise_error(Puppet::ExecutionFailure, /Execution of 'fail command' returned 1/)
      end

      it "should default failonfail to false when options are specified, but failonfail is not" do
        stub_process_wait(1)

        subject.execute('fail command', { :combine => true })
      end

      it "should default failonfail to false when an empty hash of options is specified" do
        stub_process_wait(1)

        subject.execute('fail command', {})
      end

      it "should raise an error if a nil option is specified" do
        expect {
          Puppet::Util::Execution.execute('fail command', nil)
        }.to raise_error(TypeError, /(can\'t convert|no implicit conversion of) nil into Hash/)
      end
    end
  end

  describe "#execpipe" do
    it "should execute a string as a string" do
      Puppet::Util::Execution.expects(:open).with('| echo hello 2>&1').returns('hello')
      $CHILD_STATUS.expects(:==).with(0).returns(true)
      Puppet::Util::Execution.execpipe('echo hello').should == 'hello'
    end

    it "should print meaningful debug message for string argument" do
      Puppet::Util::Execution.expects(:debug).with("Executing 'echo hello'")
      Puppet::Util::Execution.expects(:open).with('| echo hello 2>&1').returns('hello')
      $CHILD_STATUS.expects(:==).with(0).returns(true)
      Puppet::Util::Execution.execpipe('echo hello')
    end

    it "should print meaningful debug message for array argument" do
      Puppet::Util::Execution.expects(:debug).with("Executing 'echo hello'")
      Puppet::Util::Execution.expects(:open).with('| echo hello 2>&1').returns('hello')
      $CHILD_STATUS.expects(:==).with(0).returns(true)
      Puppet::Util::Execution.execpipe(['echo','hello'])
    end

    it "should execute an array by pasting together with spaces" do
      Puppet::Util::Execution.expects(:open).with('| echo hello 2>&1').returns('hello')
      $CHILD_STATUS.expects(:==).with(0).returns(true)
      Puppet::Util::Execution.execpipe(['echo', 'hello']).should == 'hello'
    end

    it "should fail if asked to fail, and the child does" do
      Puppet::Util::Execution.stubs(:open).returns('error message')
      $CHILD_STATUS.expects(:==).with(0).returns(false)
      expect { Puppet::Util::Execution.execpipe('echo hello') }.
        to raise_error Puppet::ExecutionFailure, /error message/
    end

    it "should not fail if asked not to fail, and the child does" do
      Puppet::Util::Execution.stubs(:open).returns('error message')
      $CHILD_STATUS.stubs(:==).with(0).returns(false)
      Puppet::Util::Execution.execpipe('echo hello', false).should == 'error message'
    end
  end
end
