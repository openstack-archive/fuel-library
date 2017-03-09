require 'spec_helper'

describe 'cgroups::service', :type => :class do
  context "on a Debian OS" do
    let :facts do
      {
        :osfamily               => 'Debian',
        :operatingsystem        => 'Ubuntu',
      }
    end

    it { is_expected.to contain_service('cgconfig') }
  end
end
