require 'spec_helper'

  describe 'openstack::firewall::vnc' do
    let(:title) { ['1.2.3.0/24','2.3.4.0/24','3.4.5.0/24'] }

    it do
      should contain_firewall('120 vnc ports 1.2.3.0/24')
    end

    it do
      should contain_firewall('120 vnc ports 2.3.4.0/24')
    end

    it do
      should contain_firewall('120 vnc ports 3.4.5.0/24')
    end
end
