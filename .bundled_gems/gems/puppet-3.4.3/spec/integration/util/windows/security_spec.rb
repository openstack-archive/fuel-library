#!/usr/bin/env ruby
require 'spec_helper'

require 'puppet/util/adsi'

if Puppet.features.microsoft_windows?
  class WindowsSecurityTester
    require 'puppet/util/windows/security'
    include Puppet::Util::Windows::Security
  end
end

describe "Puppet::Util::Windows::Security", :if => Puppet.features.microsoft_windows? do
  include PuppetSpec::Files

  before :all do
    @sids = {
      :current_user => Puppet::Util::Windows::Security.name_to_sid(Sys::Admin.get_login),
      :system => Win32::Security::SID::LocalSystem,
      :admin => Puppet::Util::Windows::Security.name_to_sid("Administrator"),
      :administrators => Win32::Security::SID::BuiltinAdministrators,
      :guest => Puppet::Util::Windows::Security.name_to_sid("Guest"),
      :users => Win32::Security::SID::BuiltinUsers,
      :power_users => Win32::Security::SID::PowerUsers,
      :none => Win32::Security::SID::Nobody,
      :everyone => Win32::Security::SID::Everyone
    }
  end

  let (:sids) { @sids }
  let (:winsec) { WindowsSecurityTester.new }

  def set_group_depending_on_current_user(path)
    if sids[:current_user] == sids[:system]
      # if the current user is SYSTEM, by setting the group to
      # guest, SYSTEM is automagically given full control, so instead
      # override that behavior with SYSTEM as group and a specific mode
      winsec.set_group(sids[:system], path)
      mode = winsec.get_mode(path)
      winsec.set_mode(mode & ~WindowsSecurityTester::S_IRWXG, path)
    else
      winsec.set_group(sids[:guest], path)
    end
  end

  shared_examples_for "only child owner" do
    it "should allow child owner" do
      winsec.set_owner(sids[:guest], parent)
      winsec.set_group(sids[:current_user], parent)
      winsec.set_mode(0700, parent)

      check_delete(path)
    end

    it "should deny parent owner" do
      winsec.set_owner(sids[:guest], path)
      winsec.set_group(sids[:current_user], path)
      winsec.set_mode(0700, path)

      lambda { check_delete(path) }.should raise_error(Errno::EACCES)
    end

    it "should deny group" do
      winsec.set_owner(sids[:guest], path)
      winsec.set_group(sids[:current_user], path)
      winsec.set_mode(0700, path)

      lambda { check_delete(path) }.should raise_error(Errno::EACCES)
    end

    it "should deny other" do
      winsec.set_owner(sids[:guest], path)
      winsec.set_group(sids[:current_user], path)
      winsec.set_mode(0700, path)

      lambda { check_delete(path) }.should raise_error(Errno::EACCES)
    end
  end

  shared_examples_for "a securable object" do
    describe "on a volume that doesn't support ACLs" do
      [:owner, :group, :mode].each do |p|
        it "should return nil #{p}" do
          winsec.stubs(:supports_acl?).returns false

          winsec.send("get_#{p}", path).should be_nil
        end
      end
    end

    describe "on a volume that supports ACLs" do
      describe "for a normal user" do
        before :each do
          Puppet.features.stubs(:root?).returns(false)
        end

        after :each do
          winsec.set_mode(WindowsSecurityTester::S_IRWXU, parent)
          winsec.set_mode(WindowsSecurityTester::S_IRWXU, path) if Puppet::FileSystem::File.exist?(path)
        end

        describe "#supports_acl?" do
          %w[c:/ c:\\ c:/windows/system32 \\\\localhost\\C$ \\\\127.0.0.1\\C$\\foo].each do |path|
            it "should accept #{path}" do
              winsec.should be_supports_acl(path)
            end
          end

          it "should raise an exception if it cannot get volume information" do
            expect {
              winsec.supports_acl?('foobar')
            }.to raise_error(Puppet::Error, /Failed to get volume information/)
          end
        end

        describe "#owner=" do
          it "should allow setting to the current user" do
            winsec.set_owner(sids[:current_user], path)
          end

          it "should raise an exception when setting to a different user" do
            lambda { winsec.set_owner(sids[:guest], path) }.should raise_error(Puppet::Error, /This security ID may not be assigned as the owner of this object./)
          end
        end

        describe "#owner" do
          it "it should not be empty" do
            winsec.get_owner(path).should_not be_empty
          end

          it "should raise an exception if an invalid path is provided" do
            lambda { winsec.get_owner("c:\\doesnotexist.txt") }.should raise_error(Puppet::Error, /The system cannot find the file specified./)
          end
        end

        describe "#group=" do
          it "should allow setting to a group the current owner is a member of" do
            winsec.set_group(sids[:users], path)
          end

          # Unlike unix, if the user has permission to WRITE_OWNER, which the file owner has by default,
          # then they can set the primary group to a group that the user does not belong to.
          it "should allow setting to a group the current owner is not a member of" do
            winsec.set_group(sids[:power_users], path)
          end
        end

        describe "#group" do
          it "should not be empty" do
            winsec.get_group(path).should_not be_empty
          end

          it "should raise an exception if an invalid path is provided" do
            lambda { winsec.get_group("c:\\doesnotexist.txt") }.should raise_error(Puppet::Error, /The system cannot find the file specified./)
          end
        end

        it "should preserve inherited full control for SYSTEM when setting owner and group" do
          # new file has SYSTEM
          system_aces = winsec.get_aces_for_path_by_sid(path, sids[:system])
          system_aces.should_not be_empty

          # when running under SYSTEM account, multiple ACEs come back
          # so we only care that we have at least one of these
          system_aces.any? do |ace|
            ace.mask == Windows::File::FILE_ALL_ACCESS
          end.should be_true

          # changing the owner/group will no longer make the SD protected
          winsec.set_group(sids[:power_users], path)
          winsec.set_owner(sids[:administrators], path)

          system_aces.find do |ace|
            ace.mask == Windows::File::FILE_ALL_ACCESS && ace.inherited?
          end.should_not be_nil
        end

        describe "#mode=" do
          (0000..0700).step(0100) do |mode|
            it "should enforce mode #{mode.to_s(8)}" do
              winsec.set_mode(mode, path)

              check_access(mode, path)
            end
          end

          it "should round-trip all 128 modes that do not require deny ACEs" do
            0.upto(1).each do |s|
              0.upto(7).each do |u|
                0.upto(u).each do |g|
                  0.upto(g).each do |o|
                    # if user is superset of group, and group superset of other, then
                    # no deny ace is required, and mode can be converted to win32
                    # access mask, and back to mode without loss of information
                    # (provided the owner and group are not the same)
                    next if ((u & g) != g) or ((g & o) != o)

                    mode = (s << 9 | u << 6 | g << 3 | o << 0)
                    winsec.set_mode(mode, path)
                    winsec.get_mode(path).to_s(8).should == mode.to_s(8)
                  end
                end
              end
            end
          end

          it "should preserve full control for SYSTEM when setting mode" do
            # new file has SYSTEM
            system_aces = winsec.get_aces_for_path_by_sid(path, sids[:system])
            system_aces.should_not be_empty

            # when running under SYSTEM account, multiple ACEs come back
            # so we only care that we have at least one of these
            system_aces.any? do |ace|
              ace.mask == WindowsSecurityTester::FILE_ALL_ACCESS
            end.should be_true

            # changing the mode will make the SD protected
            winsec.set_group(sids[:none], path)
            winsec.set_mode(0600, path)

            # and should have a non-inherited SYSTEM ACE(s)
            system_aces = winsec.get_aces_for_path_by_sid(path, sids[:system])
            system_aces.each do |ace|
              ace.mask.should == Windows::File::FILE_ALL_ACCESS && ! ace.inherited?
            end
          end

          describe "for modes that require deny aces" do
            it "should map everyone to group and owner" do
              winsec.set_mode(0426, path)
              winsec.get_mode(path).to_s(8).should == "666"
            end

            it "should combine user and group modes when owner and group sids are equal" do
              winsec.set_group(winsec.get_owner(path), path)

              winsec.set_mode(0410, path)
              winsec.get_mode(path).to_s(8).should == "550"
            end
          end

          describe "for read-only objects" do
            before :each do
              winsec.set_group(sids[:none], path)
              winsec.set_mode(0600, path)
              winsec.add_attributes(path, WindowsSecurityTester::FILE_ATTRIBUTE_READONLY)
              (winsec.get_attributes(path) & WindowsSecurityTester::FILE_ATTRIBUTE_READONLY).should be_nonzero
            end

            it "should make them writable if any sid has write permission" do
              winsec.set_mode(WindowsSecurityTester::S_IWUSR, path)
              (winsec.get_attributes(path) & WindowsSecurityTester::FILE_ATTRIBUTE_READONLY).should == 0
            end

            it "should leave them read-only if no sid has write permission and should allow full access for SYSTEM" do
              winsec.set_mode(WindowsSecurityTester::S_IRUSR | WindowsSecurityTester::S_IXGRP, path)
              (winsec.get_attributes(path) & WindowsSecurityTester::FILE_ATTRIBUTE_READONLY).should be_nonzero

              system_aces = winsec.get_aces_for_path_by_sid(path, sids[:system])

              # when running under SYSTEM account, and set_group / set_owner hasn't been called
              # SYSTEM full access will be restored
              system_aces.any? do |ace|
                ace.mask == Windows::File::FILE_ALL_ACCESS
              end.should be_true
            end
          end

          it "should raise an exception if an invalid path is provided" do
            lambda { winsec.set_mode(sids[:guest], "c:\\doesnotexist.txt") }.should raise_error(Puppet::Error, /The system cannot find the file specified./)
          end
        end

        describe "#mode" do
          it "should report when extra aces are encounted" do
            sd = winsec.get_security_descriptor(path)
            (544..547).each do |rid|
              sd.dacl.allow("S-1-5-32-#{rid}", WindowsSecurityTester::STANDARD_RIGHTS_ALL)
            end
            winsec.set_security_descriptor(path, sd)

            mode = winsec.get_mode(path)
            (mode & WindowsSecurityTester::S_IEXTRA).should == WindowsSecurityTester::S_IEXTRA
          end

          it "should return deny aces" do
            sd = winsec.get_security_descriptor(path)
            sd.dacl.deny(sids[:guest], WindowsSecurityTester::FILE_GENERIC_WRITE)
            winsec.set_security_descriptor(path, sd)

            guest_aces = winsec.get_aces_for_path_by_sid(path, sids[:guest])
            guest_aces.find do |ace|
              ace.type == WindowsSecurityTester::ACCESS_DENIED_ACE_TYPE
            end.should_not be_nil
          end

          it "should skip inherit-only ace" do
            sd = winsec.get_security_descriptor(path)
            dacl = Puppet::Util::Windows::AccessControlList.new
            dacl.allow(
              sids[:current_user], WindowsSecurityTester::STANDARD_RIGHTS_ALL | WindowsSecurityTester::SPECIFIC_RIGHTS_ALL
            )
            dacl.allow(
              sids[:everyone],
              WindowsSecurityTester::FILE_GENERIC_READ,
              WindowsSecurityTester::INHERIT_ONLY_ACE | WindowsSecurityTester::OBJECT_INHERIT_ACE
            )
            winsec.set_security_descriptor(path, sd)

            (winsec.get_mode(path) & WindowsSecurityTester::S_IRWXO).should == 0
          end

          it "should raise an exception if an invalid path is provided" do
            lambda { winsec.get_mode("c:\\doesnotexist.txt") }.should raise_error(Puppet::Error, /The system cannot find the file specified./)
          end
        end

        describe "inherited access control entries" do
          it "should be absent when the access control list is protected, and should not remove SYSTEM" do
            winsec.set_mode(WindowsSecurityTester::S_IRWXU, path)

            mode = winsec.get_mode(path)
            [ WindowsSecurityTester::S_IEXTRA,
              WindowsSecurityTester::S_ISYSTEM_MISSING ].each do |flag|
              (mode & flag).should_not == flag
            end
          end

          it "should be present when the access control list is unprotected" do
            # add a bunch of aces to the parent with permission to add children
            allow = WindowsSecurityTester::STANDARD_RIGHTS_ALL | WindowsSecurityTester::SPECIFIC_RIGHTS_ALL
            inherit = WindowsSecurityTester::OBJECT_INHERIT_ACE | WindowsSecurityTester::CONTAINER_INHERIT_ACE

            sd = winsec.get_security_descriptor(parent)
            sd.dacl.allow(
              "S-1-1-0", #everyone
              allow,
              inherit
            )
            (544..547).each do |rid|
              sd.dacl.allow(
                "S-1-5-32-#{rid}",
                WindowsSecurityTester::STANDARD_RIGHTS_ALL,
                inherit
              )
            end
            winsec.set_security_descriptor(parent, sd)

            # unprotect child, it should inherit from parent
            winsec.set_mode(WindowsSecurityTester::S_IRWXU, path, false)
            (winsec.get_mode(path) & WindowsSecurityTester::S_IEXTRA).should == WindowsSecurityTester::S_IEXTRA
          end
        end
      end

      describe "for an administrator", :if => Puppet.features.root? do
        before :each do
          winsec.set_mode(WindowsSecurityTester::S_IRWXU | WindowsSecurityTester::S_IRWXG, path)
          set_group_depending_on_current_user(path)
          winsec.set_owner(sids[:guest], path)
          lambda { File.open(path, 'r') }.should raise_error(Errno::EACCES)
        end

        after :each do
          if Puppet::FileSystem::File.exist?(path)
            winsec.set_owner(sids[:current_user], path)
            winsec.set_mode(WindowsSecurityTester::S_IRWXU, path)
          end
        end

        describe "#owner=" do
          it "should accept a user sid" do
            winsec.set_owner(sids[:admin], path)
            winsec.get_owner(path).should == sids[:admin]
          end

          it "should accept a group sid" do
            winsec.set_owner(sids[:power_users], path)
            winsec.get_owner(path).should == sids[:power_users]
          end

          it "should raise an exception if an invalid sid is provided" do
            lambda { winsec.set_owner("foobar", path) }.should raise_error(Puppet::Error, /Failed to convert string SID/)
          end

          it "should raise an exception if an invalid path is provided" do
            lambda { winsec.set_owner(sids[:guest], "c:\\doesnotexist.txt") }.should raise_error(Puppet::Error, /The system cannot find the file specified./)
          end
        end

        describe "#group=" do
          it "should accept a group sid" do
            winsec.set_group(sids[:power_users], path)
            winsec.get_group(path).should == sids[:power_users]
          end

          it "should accept a user sid" do
            winsec.set_group(sids[:admin], path)
            winsec.get_group(path).should == sids[:admin]
          end

          it "should combine owner and group rights when they are the same sid" do
            winsec.set_owner(sids[:power_users], path)
            winsec.set_group(sids[:power_users], path)
            winsec.set_mode(0610, path)

            winsec.get_owner(path).should == sids[:power_users]
            winsec.get_group(path).should == sids[:power_users]
            # note group execute permission added to user ace, and then group rwx value
            # reflected to match

            # Exclude missing system ace, since that's not relevant
            (winsec.get_mode(path) & 0777).to_s(8).should == "770"
          end

          it "should raise an exception if an invalid sid is provided" do
            lambda { winsec.set_group("foobar", path) }.should raise_error(Puppet::Error, /Failed to convert string SID/)
          end

          it "should raise an exception if an invalid path is provided" do
            lambda { winsec.set_group(sids[:guest], "c:\\doesnotexist.txt") }.should raise_error(Puppet::Error, /The system cannot find the file specified./)
          end
        end

        describe "when the sid is NULL" do
          it "should retrieve an empty owner sid"
          it "should retrieve an empty group sid"
        end

        describe "when the sid refers to a deleted trustee" do
          it "should retrieve the user sid" do
            sid = nil
            user = Puppet::Util::ADSI::User.create("delete_me_user")
            user.commit
            begin
              sid = Sys::Admin::get_user(user.name).sid
              winsec.set_owner(sid, path)
              winsec.set_mode(WindowsSecurityTester::S_IRWXU, path)
            ensure
              Puppet::Util::ADSI::User.delete(user.name)
            end

            winsec.get_owner(path).should == sid
            winsec.get_mode(path).should == WindowsSecurityTester::S_IRWXU
          end

          it "should retrieve the group sid" do
            sid = nil
            group = Puppet::Util::ADSI::Group.create("delete_me_group")
            group.commit
            begin
              sid = Sys::Admin::get_group(group.name).sid
              winsec.set_group(sid, path)
              winsec.set_mode(WindowsSecurityTester::S_IRWXG, path)
            ensure
              Puppet::Util::ADSI::Group.delete(group.name)
            end
            winsec.get_group(path).should == sid
            winsec.get_mode(path).should == WindowsSecurityTester::S_IRWXG
          end
        end

        describe "#mode" do
          it "should deny all access when the DACL is empty, including SYSTEM" do
            sd = winsec.get_security_descriptor(path)
            # don't allow inherited aces to affect the test
            protect = true
            new_sd = Puppet::Util::Windows::SecurityDescriptor.new(sd.owner, sd.group, [], protect)
            winsec.set_security_descriptor(path, new_sd)

            winsec.get_mode(path).should == WindowsSecurityTester::S_ISYSTEM_MISSING
          end

          # REMIND: ruby crashes when trying to set a NULL DACL
          # it "should allow all when it is nil" do
          #   winsec.set_owner(sids[:current_user], path)
          #   winsec.open_file(path, WindowsSecurityTester::READ_CONTROL | WindowsSecurityTester::WRITE_DAC) do |handle|
          #     winsec.set_security_info(handle, WindowsSecurityTester::DACL_SECURITY_INFORMATION | WindowsSecurityTester::PROTECTED_DACL_SECURITY_INFORMATION, nil)
          #   end
          #   winsec.get_mode(path).to_s(8).should == "777"
          # end
        end

        describe "when the parent directory" do
          before :each do
            winsec.set_owner(sids[:current_user], parent)
            winsec.set_owner(sids[:current_user], path)
            winsec.set_mode(0777, path, false)
          end

          describe "is writable and executable" do
            describe "and sticky bit is set" do
              it "should allow child owner" do
                winsec.set_owner(sids[:guest], parent)
                winsec.set_group(sids[:current_user], parent)
                winsec.set_mode(01700, parent)

                check_delete(path)
              end

              it "should allow parent owner" do
                winsec.set_owner(sids[:current_user], parent)
                winsec.set_group(sids[:guest], parent)
                winsec.set_mode(01700, parent)

                winsec.set_owner(sids[:current_user], path)
                winsec.set_group(sids[:guest], path)
                winsec.set_mode(0700, path)

                check_delete(path)
              end

              it "should deny group" do
                winsec.set_owner(sids[:guest], parent)
                winsec.set_group(sids[:current_user], parent)
                winsec.set_mode(01770, parent)

                winsec.set_owner(sids[:guest], path)
                winsec.set_group(sids[:current_user], path)
                winsec.set_mode(0700, path)

                lambda { check_delete(path) }.should raise_error(Errno::EACCES)
              end

              it "should deny other" do
                winsec.set_owner(sids[:guest], parent)
                winsec.set_group(sids[:current_user], parent)
                winsec.set_mode(01777, parent)

                winsec.set_owner(sids[:guest], path)
                winsec.set_group(sids[:current_user], path)
                winsec.set_mode(0700, path)

                lambda { check_delete(path) }.should raise_error(Errno::EACCES)
              end
            end

            describe "and sticky bit is not set" do
              it "should allow child owner" do
                winsec.set_owner(sids[:guest], parent)
                winsec.set_group(sids[:current_user], parent)
                winsec.set_mode(0700, parent)

                check_delete(path)
              end

              it "should allow parent owner" do
                winsec.set_owner(sids[:current_user], parent)
                winsec.set_group(sids[:guest], parent)
                winsec.set_mode(0700, parent)

                winsec.set_owner(sids[:current_user], path)
                winsec.set_group(sids[:guest], path)
                winsec.set_mode(0700, path)

                check_delete(path)
              end

              it "should allow group" do
                winsec.set_owner(sids[:guest], parent)
                winsec.set_group(sids[:current_user], parent)
                winsec.set_mode(0770, parent)

                winsec.set_owner(sids[:guest], path)
                winsec.set_group(sids[:current_user], path)
                winsec.set_mode(0700, path)

                check_delete(path)
              end

              it "should allow other" do
                winsec.set_owner(sids[:guest], parent)
                winsec.set_group(sids[:current_user], parent)
                winsec.set_mode(0777, parent)

                winsec.set_owner(sids[:guest], path)
                winsec.set_group(sids[:current_user], path)
                winsec.set_mode(0700, path)

                check_delete(path)
              end
            end
          end

          describe "is not writable" do
            before :each do
              winsec.set_group(sids[:current_user], parent)
              winsec.set_mode(0555, parent)
            end

            it_behaves_like "only child owner"
          end

          describe "is not executable" do
            before :each do
              winsec.set_group(sids[:current_user], parent)
              winsec.set_mode(0666, parent)
            end

            it_behaves_like "only child owner"
          end
        end
      end
    end
  end

  describe "file" do
    let (:parent) do
      tmpdir('win_sec_test_file')
    end

    let (:path) do
      path = File.join(parent, 'childfile')
      File.new(path, 'w').close
      path
    end

    it_behaves_like "a securable object" do
      def check_access(mode, path)
        if (mode & WindowsSecurityTester::S_IRUSR).nonzero?
          check_read(path)
        else
          lambda { check_read(path) }.should raise_error(Errno::EACCES)
        end

        if (mode & WindowsSecurityTester::S_IWUSR).nonzero?
          check_write(path)
        else
          lambda { check_write(path) }.should raise_error(Errno::EACCES)
        end

        if (mode & WindowsSecurityTester::S_IXUSR).nonzero?
          lambda { check_execute(path) }.should raise_error(Errno::ENOEXEC)
        else
          lambda { check_execute(path) }.should raise_error(Errno::EACCES)
        end
      end

      def check_read(path)
        File.open(path, 'r').close
      end

      def check_write(path)
        File.open(path, 'w').close
      end

      def check_execute(path)
        Kernel.exec(path)
      end

      def check_delete(path)
        File.delete(path)
      end
    end

    describe "locked files" do
      let (:explorer) { File.join(Dir::WINDOWS, "explorer.exe") }

      it "should get the owner" do
        winsec.get_owner(explorer).should match /^S-1-5-/
      end

      it "should get the group" do
        winsec.get_group(explorer).should match /^S-1-5-/
      end

      it "should get the mode" do
        winsec.get_mode(explorer).should == (WindowsSecurityTester::S_IRWXU | WindowsSecurityTester::S_IRWXG | WindowsSecurityTester::S_IEXTRA)
      end
    end
  end

  describe "directory" do
    let (:parent) do
      tmpdir('win_sec_test_dir')
    end

    let (:path) do
      path = File.join(parent, 'childdir')
      Dir.mkdir(path)
      path
    end

    it_behaves_like "a securable object" do
      def check_access(mode, path)
        if (mode & WindowsSecurityTester::S_IRUSR).nonzero?
          check_read(path)
        else
          lambda { check_read(path) }.should raise_error(Errno::EACCES)
        end

        if (mode & WindowsSecurityTester::S_IWUSR).nonzero?
          check_write(path)
        else
          lambda { check_write(path) }.should raise_error(Errno::EACCES)
        end

        if (mode & WindowsSecurityTester::S_IXUSR).nonzero?
          check_execute(path)
        else
          lambda { check_execute(path) }.should raise_error(Errno::EACCES)
        end
      end

      def check_read(path)
        Dir.entries(path)
      end

      def check_write(path)
        Dir.mkdir(File.join(path, "subdir"))
      end

      def check_execute(path)
        Dir.chdir(path) {}
      end

      def check_delete(path)
        Dir.rmdir(path)
      end
    end

    describe "inheritable aces" do
      it "should be applied to child objects" do
        mode640 = WindowsSecurityTester::S_IRUSR | WindowsSecurityTester::S_IWUSR | WindowsSecurityTester::S_IRGRP
        winsec.set_mode(mode640, path)

        newfile = File.join(path, "newfile.txt")
        File.new(newfile, "w").close

        newdir = File.join(path, "newdir")
        Dir.mkdir(newdir)

        [newfile, newdir].each do |p|
          mode = winsec.get_mode(p)
          (mode & 07777).to_s(8).should == mode640.to_s(8)
        end
      end
    end
  end

  context "security descriptor" do
    let(:path) { tmpfile('sec_descriptor') }
    let(:read_execute) { 0x201FF }
    let(:synchronize)  { 0x100000 }

    before :each do
      FileUtils.touch(path)
    end

    it "preserves aces for other users" do
      dacl = Puppet::Util::Windows::AccessControlList.new
      sids_in_dacl = [sids[:current_user], sids[:users]]
      sids_in_dacl.each do |sid|
        dacl.allow(sid, read_execute)
      end
      sd = Puppet::Util::Windows::SecurityDescriptor.new(sids[:guest], sids[:guest], dacl, true)
      winsec.set_security_descriptor(path, sd)

      aces = winsec.get_security_descriptor(path).dacl.to_a
      aces.map(&:sid).should == sids_in_dacl
      aces.map(&:mask).all? { |mask| mask == read_execute }.should be_true
    end

    it "changes the sid for all aces that were assigned to the old owner" do
      sd = winsec.get_security_descriptor(path)
      sd.owner.should_not == sids[:guest]

      sd.dacl.allow(sd.owner, read_execute)
      sd.dacl.allow(sd.owner, synchronize)

      sd.owner = sids[:guest]
      winsec.set_security_descriptor(path, sd)

      dacl = winsec.get_security_descriptor(path).dacl
      aces = dacl.find_all { |ace| ace.sid == sids[:guest] }
      # only non-inherited aces will be reassigned to guest, so
      # make sure we find at least the two we added
      aces.size.should >= 2
    end

    it "preserves INHERIT_ONLY_ACEs" do
      # inherit only aces can only be set on directories
      dir = tmpdir('inheritonlyace')

      inherit_flags = Puppet::Util::Windows::AccessControlEntry::INHERIT_ONLY_ACE |
        Puppet::Util::Windows::AccessControlEntry::OBJECT_INHERIT_ACE |
        Puppet::Util::Windows::AccessControlEntry::CONTAINER_INHERIT_ACE

      sd = winsec.get_security_descriptor(dir)
      sd.dacl.allow(sd.owner, Windows::File::FILE_ALL_ACCESS, inherit_flags)
      winsec.set_security_descriptor(dir, sd)

      sd = winsec.get_security_descriptor(dir)

      winsec.set_owner(sids[:guest], dir)

      sd = winsec.get_security_descriptor(dir)
      sd.dacl.find do |ace|
        ace.sid == sids[:guest] && ace.inherit_only?
      end.should_not be_nil
    end

    context "when managing mode" do
      it "removes aces for sids that are neither the owner nor group" do
        # add a guest ace, it's never owner or group
        sd = winsec.get_security_descriptor(path)
        sd.dacl.allow(sids[:guest], read_execute)
        winsec.set_security_descriptor(path, sd)

        # setting the mode, it should remove extra aces
        winsec.set_mode(0770, path)

        # make sure it's gone
        dacl = winsec.get_security_descriptor(path).dacl
        aces = dacl.find_all { |ace| ace.sid == sids[:guest] }
        aces.should be_empty
      end
    end
  end
end
