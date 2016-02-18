require 'spec_helper'

describe 'cgroups', :type => :class do
#  shared_examples 'cgroups' do

  context "on a Debian OS" do
    let(:facts) do
      {
        :osfamily        => 'Debian',
        :operatingsystem => 'Ubuntu',
      }
    end
#  end

#  context 'with default parameters' do
#    describe 'check packages' do
      it { should contain_package('cgroup_bin') }
      it { should contain_package('libcgroup1') }
#    end
#    describe 'check files' do
      it { should contain_file('cgconfig.conf').with(
        :path => '/etc/cgconfig.conf'
      ) }
      it { should contain_file('/etc/cgrules.conf').with(
        :path => '/etc/cgrules.conf'
      ) }
#    end
  end

#  end
end
