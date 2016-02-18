require 'spec_helper'

describe 'cgroups::service', :type => :class do
  context "on a Debian OS" do
    let :facts do
      {
        :osfamily               => 'Debian',
        :operatingsystem        => 'Ubuntu',
      }
    end

    %w(cgroup-lite cgconfigparser cgrulesengd).each do |cg_service|
      it { is_expected.to contain_service(cg_service) }
    end
  end
end
