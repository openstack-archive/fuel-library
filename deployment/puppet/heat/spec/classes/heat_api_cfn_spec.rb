require 'spec_helper'

describe 'heat::api_cfn' do

  let :params do
    {
      :bind_host => '127.0.0.1',
      :bind_port => '1234',
      :workers   => '0'
    }
  end

  let :facts do
    { :osfamily => 'Debian' }
  end

  context 'config params' do

    it { should contain_class('heat') }
    it { should contain_class('heat::params') }

    it { should contain_heat_config('heat_api_cfn/bind_host').with_value( params[:bind_host] ) }
    it { should contain_heat_config('heat_api_cfn/bind_port').with_value( params[:bind_port] ) }
    it { should contain_heat_config('heat_api_cfn/workers').with_value( params[:workers] ) }

  end

end
