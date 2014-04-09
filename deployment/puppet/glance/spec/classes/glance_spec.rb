require 'spec_helper'

describe 'glance' do

  let :facts do
    {
      :osfamily => 'Debian'
    }
  end

  let :default_params do
    {:package_ensure => 'present'}
  end

  [
    {},
    {:package_ensure => 'latest'}
  ].each do |param_set|

    describe "when #{param_set == {} ? "using default" : "specifying"} class parameters" do

      let :param_hash do
        param_set == {} ? default_params : params
      end

      let :params do param_set end

      it { should contain_package('glance').with_ensure(param_hash[:package_ensure]) }
      it { should contain_file('/etc/glance/').with(
        'ensure'  => 'directory',
        'owner'   => 'glance',
        'mode'    => '0770',
        'require' => 'Package[glance]'
      )}
    end
  end
end
