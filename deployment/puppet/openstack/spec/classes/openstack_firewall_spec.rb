require 'spec_helper'

  describe 'openstack::firewall' do
    let(:params) { {:nova_vnc_ip_range => ['1.2.3.0/24','2.3.4.0/24','3.4.5.0/24']} }

    it do
      should contain_firewall('120 vnc ports for 1.2.3.0/24')
      should contain_firewall('120 vnc ports for 2.3.4.0/24')
      should contain_firewall('120 vnc ports for 3.4.5.0/24')
    end
end
