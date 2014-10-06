require 'spec_helper'
require File.join(File.dirname(__FILE__), '../lib/base')
require File.join(File.dirname(__FILE__), '../lib/package')

class PackageTest
  include Base
  include Package
end

describe PackageTest do

  let(:deb_packages) do
<<-eos
mc|3:4.8.11-1|deinstall ok config-files
ipcalc|0.41-4|install ok installed
iproute|3.12.0-2|install ok installed
iptables|1.4.21-1ubuntu1|install ok installed
ntpdate|4.2.6.p5+dfsg-3ubuntu2|install ok installed
mc|3:4.8.11-1|install ok installed
eos
  end

  let(:deb_packages_list) do
    {
        "iptables"=>"1.4.21-1ubuntu1",
        "iproute"=>"3.12.0-2",
        "ipcalc"=>"0.41-4",
        "ntpdate" =>"4.2.6.p5+dfsg-3ubuntu2",
        "mc" => "3:4.8.11-1",
    }
  end

  let(:rpm_packages) do
<<-eos
iproute|2.6.32-130.el6.netns.2.mira1
util-linux-ng|2.17.2-12.14.el6_5
udev|147-2.51.el6
device-mapper|1.02.79-8.el6
openssh|5.3p1-94.el6
ntpdate|4.2.6p5-1.el6
mc|1:4.7.0.2-3.el6
eos
  end

  let(:rpm_packages_list) do
    {
        "util-linux-ng"=>"2.17.2-12.14.el6_5",
        "iproute"=>"2.6.32-130.el6.netns.2.mira1",
        "openssh"=>"5.3p1-94.el6",
        "udev"=>"147-2.51.el6",
        "device-mapper"=>"1.02.79-8.el6",
        "ntpdate"=>"4.2.6p5-1.el6",
        "mc"=>"1:4.7.0.2-3.el6",
    }
  end

  let(:packages_to_remove) do
    %w(iproute mc firefox ntpdate)
  end

  let(:deb_remove_out) do
<<-eos
(Reading database ... 463883 files and directories currently installed.)
Removing mc (3:4.8.11-1) ...
Purging configuration files for mc (3:4.8.11-1) ...
Removing mc-data ...
eos
  end

  let(:key_packages) do
    %w(mc firefox)
  end

  let(:deb_remove_list) do
    %w(mc mc-data)
  end

  let(:rpm_remove_out) do
    <<-eos
Dependencies Resolved

=======================================================================================================================================================================
 Package                                Arch                                Version                                        Repository                             Size
=======================================================================================================================================================================
Removing:
 htop                                   x86_64                              1.0.1-2.el6                                    @nailgun                              161 k
 mc                                     x86_64                              1:4.7.0.2-3.el6                                @nailgun                              5.4 M
 tmux                                   x86_64                              1.6-3.el6                                      @nailgun                              494 k
 yum-utils                              noarch                              1.1.30-17.el6_5                                @nailgun                              302 k

Transaction Summary
=======================================================================================================================================================================
Remove        4 Package(s)                                                                                                                        3/3
    eos
  end

  let(:rpm_remove_list) do
    ["htop", "mc", "tmux", "yum-utils"]
  end

  ###########################

  before(:each) do
    @class = subject
    @class.dry_run = true
    @class.stubs(:log).returns true
  end

  context 'on Debian system' do
    before(:each) do
      @class.stubs(:get_rpm_packages).returns rpm_packages
      @class.stubs(:get_deb_packages).returns deb_packages
      @class.stubs(:osfamily).returns 'Debian'
    end

    it 'parses package list' do
      expect(@class.parse_deb_packages).to eq deb_packages_list
    end

    it 'determines if a package is installed' do
      @class.installed_packages_with_renew
      expect(@class.is_installed? 'iproute').to be_truthy
    end

    it 'determines if a package is not installed' do
      @class.installed_packages_with_renew
      expect(@class.is_installed? 'firefox').to be_falsey
    end

    it 'filters out not installed packages' do
      @class.installed_packages_with_renew
      expect(@class.filter_installed packages_to_remove).to eq %w(iproute mc ntpdate)
    end

    it 'uninstalls only installed packages from the list' do
      @class.installed_packages_with_renew
      @class.expects(:remove).with(%w(iproute mc ntpdate))
      @class.uninstall_packages packages_to_remove
    end

    it 'uses aptitude remove -y to remove packages' do
      @class.installed_packages_with_renew
      @class.expects(:run).with 'aptitude remove -y iproute ntpdate'
      @class.stubs(:dpkg_configure_all).returns true
      @class.remove %w(iproute ntpdate)
    end

    it 'uses aptitude install -y to install packages' do
      @class.installed_packages_with_renew
      @class.expects(:run).with 'aptitude install -y iproute ntpdate'
      @class.stubs(:dpkg_configure_all).returns true
      @class.install %w(iproute ntpdate)
    end

    it 'runs dpkg --configure -a after install and remove' do
      @class.installed_packages_with_renew
      @class.stubs(:run).returns true
      @class.stubs(:parse_deb_remove).returns true
      @class.expects(:dpkg_configure_all).twice
      @class.install %w(iproute ntpdate)
      @class.remove %w(iproute ntpdate)
    end

    it 'parses deb remove output' do
      @class.stubs(:run).returns [deb_remove_out, 0]
      @class.remove %w('mc', 'mc-data')
      expect(@class.removed_packages).to eq deb_remove_list
    end

    context 'on reinstall' do
      it 'installs only those key packages that were removed' do
        @class.stubs(:removed_packages).returns deb_remove_list
        @class.expects(:install).with %w(mc)
        @class.install_removed_packages key_packages
      end

      it 'installs all key packages in no removed present' do
        @class.stubs(:removed_packages).returns({})
        @class.expects(:install).with key_packages
        @class.install_removed_packages key_packages
      end

      it 'installs all removed packages' do
        @class.stubs(:removed_packages).returns deb_remove_list
        @class.expects(:install).with deb_remove_list
        @class.install_removed_packages
      end

      it 'reinstalls removed packages' do
        @class.expects(:remove).with(packages_to_remove - ['firefox'])
        @class.stubs(:removed_packages).returns rpm_remove_list
        @class.expects(:install).with rpm_remove_list
        @class.reinstall_with_remove packages_to_remove
      end
    end

    it 'uses apt-get clean to reset repos' do
      @class.expects(:run).with 'apt-get clean'
      @class.expects(:run).with 'apt-get update'
      @class.reset_repos
    end

  end

  context 'on RedHat system' do
    before(:each) do
      @class.stubs(:get_rpm_packages).returns rpm_packages
      @class.stubs(:get_deb_packages).returns deb_packages
      @class.stubs(:osfamily).returns 'RedHat'
    end

    it 'parses package list' do
      expect(@class.parse_rpm_packages).to eq rpm_packages_list
    end

    it 'determines if a package is installed' do
      @class.installed_packages_with_renew
      expect(@class.is_installed? 'iproute').to be_truthy
    end

    it 'determines if a package is not installed' do
      @class.installed_packages_with_renew
      expect(@class.is_installed? 'firefox').to be_falsey
    end

    it 'filters out not installed packages' do
      @class.installed_packages_with_renew
      expect(@class.filter_installed packages_to_remove).to eq %w(iproute mc ntpdate)
    end

    it 'uninstalls only installed packages from the list' do
      @class.installed_packages_with_renew
      @class.expects(:remove).with(%w(iproute mc ntpdate))
      @class.uninstall_packages packages_to_remove
    end

    it 'uses yum erase -y to remove packages' do
      @class.installed_packages_with_renew
      @class.expects(:run).with 'yum erase -y iproute ntpdate'
      @class.remove %w(iproute ntpdate)
    end

    it 'uses yum install -y to install packages' do
      @class.installed_packages_with_renew
      @class.expects(:run).with 'yum install -y iproute ntpdate'
      @class.install %w(iproute ntpdate)
    end

    it 'parses rpm remove output' do
      @class.stubs(:run).returns [rpm_remove_out, 0]
      @class.remove %w('htop', 'tmux', mc', 'yum-utils')
      expect(@class.removed_packages).to eq rpm_remove_list
    end

    context 'on reinstall' do
      it 'installs only those key packages that were removed' do
        @class.stubs(:removed_packages).returns rpm_remove_list
        @class.expects(:install).with %w(mc)
        @class.install_removed_packages key_packages
      end

      it 'installs all key packages in no removed present' do
        @class.stubs(:removed_packages).returns({})
        @class.expects(:install).with key_packages
        @class.install_removed_packages key_packages
      end

      it 'installs all removed packages if no key packages present' do
        @class.stubs(:removed_packages).returns rpm_remove_list
        @class.expects(:install).with rpm_remove_list
        @class.install_removed_packages
      end

      it 'reinstalls removed packages' do
        @class.expects(:remove).with(packages_to_remove - ['firefox'])
        @class.stubs(:removed_packages).returns(rpm_remove_list)
        @class.expects(:install).with(rpm_remove_list)
        @class.reinstall_with_remove packages_to_remove
      end
    end

    it 'uses yum clean all to reset repos' do
      @class.expects(:run).with 'yum clean all'
      @class.expects(:run).with 'yum makecache'
      @class.reset_repos
    end

  end

end
