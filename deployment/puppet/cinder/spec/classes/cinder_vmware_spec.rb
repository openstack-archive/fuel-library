require 'spec_helper'

describe 'cinder::vmware' do

  let :params do
    {:os_password => 'asdf',
     :os_tenant_name => 'admin',
     :os_username => 'admin',
     :os_auth_url => 'http://127.127.127.1:5000/v2.0/'}
  end

  describe 'with defaults' do
    it 'should create vmware special types' do
      is_expected.to contain_cinder__type('vmware-thin').with(
                 :set_key => 'vmware:vmdk_type',
                 :set_value => 'thin')

      is_expected.to contain_cinder__type('vmware-thick').with(
                 :set_key => 'vmware:vmdk_type',
                 :set_value => 'thick')

      is_expected.to contain_cinder__type('vmware-eagerZeroedThick').with(
                 :set_key => 'vmware:vmdk_type',
                 :set_value => 'eagerZeroedThick')

      is_expected.to contain_cinder__type('vmware-full').with(
                 :set_key => 'vmware:clone_type',
                 :set_value => 'full')

      is_expected.to contain_cinder__type('vmware-linked').with(
                 :set_key => 'vmware:clone_type',
                 :set_value => 'linked')
    end
  end
end
