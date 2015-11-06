require 'spec_helper'

  describe 'openstack::firewall' do
    let(:params) { {:nova_vnc_ip_range => ['1.2.3.0/24','2.3.4.0/24','3.4.5.0/24']} }
    let(:params) { {:iscsi_ip => ['9.9.9.9']} }
    let(:facts) { {:kernel => 'Linux'} }

    it 'should contain firewall rules for all nova vnc ip ranges' do
      should contain_firewall('120 vnc ports for 1.2.3.0/24')
      should contain_firewall('120 vnc ports for 2.3.4.0/24')
      should contain_firewall('120 vnc ports for 3.4.5.0/24')
    end

    it 'should contain firewall rules for all iscsi ip ranges' do
      should contain_firewall('120 iscsi ').with(
        :destination => '9.9.9.9',
      )
    end
end
