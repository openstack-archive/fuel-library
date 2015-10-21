require 'spec_helper'

  describe 'openstack::firewall' do
    let(:title) { '1.2.3.0/24' }

    it { should contain_firewall('120 vnc ports for 1.2.3.0/24') }

end
