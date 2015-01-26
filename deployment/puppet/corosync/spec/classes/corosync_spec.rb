require 'spec_helper'

describe 'corosync', :type => :class do
  context "on a Debian OS" do
    let :facts do
      {
        :processorcount => '3',
        :ipaddress      => '127.0.0.1',
        :osfamily       => 'Debian'
      }
    end
    let :params do
      { :multicast_address => '239.1.1.2' }
    end
    it { is_expected.to compile }
  end
end
