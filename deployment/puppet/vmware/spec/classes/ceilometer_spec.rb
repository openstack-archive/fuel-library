require 'spec_helper'

describe 'vmware::ceilometer' do
  let(:facts) { { :osfamily => 'debian' } }

  it 'should enable ceilometer-polling' do
    should contain_service('ceilometer-polling').with({
      'enabled' => 'true'
    })
  end

end
