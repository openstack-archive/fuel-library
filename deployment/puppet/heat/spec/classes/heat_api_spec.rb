require 'spec_helper'

describe 'heat::api' do

  let :params do
    {
      :bind_host => '127.0.0.1',
      :bind_port => '1234'
    }
  end

  let :facts do
    { :osfamily => 'Debian' }
  end

  context 'config params' do

    it { should include_class('heat') }
    it { should include_class('heat::params') }

    it { should contain_heat_config('heat_api/bind_host').with_value( params[:bind_host] ) }
    it { should contain_heat_config('heat_api/bind_port').with_value( params[:bind_port] ) }

  end

end
