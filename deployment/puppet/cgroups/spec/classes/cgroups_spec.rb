require 'spec_helper'

describe 'cgroups', :type => :class do

  context "on a Debian OS" do
    let(:facts) do
      {
        :osfamily        => 'Debian',
        :operatingsystem => 'Ubuntu',
      }
    end

      it { should contain_package('cgroup_bin') }
      it { should contain_package('libcgroup1') }
      it { should contain_file('/etc/cgconfig.conf') }
      it { should contain_file('/etc/cgrules.conf') }
      it { is_expected.to compile }
  end
end
