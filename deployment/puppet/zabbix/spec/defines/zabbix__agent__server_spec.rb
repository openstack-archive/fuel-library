require 'spec_helper'

describe 'zabbix::agent::server' do
  context "with params" do
    let :params do
      {
        :ensure   => 'undef',
        :hostname => 'undef'
      }
    end
  end
end  