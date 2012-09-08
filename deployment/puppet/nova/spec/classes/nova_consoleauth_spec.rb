require 'spec_helper'

describe 'nova::consoleauth' do

  let :pre_condition do
    'include nova'
  end

  describe 'on debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    describe 'with package version' do
      let :params do
        {:ensure_package => '2012.1-2'}
      end
      it { should contain_package('nova-consoleauth').with(
        'ensure' => '2012.1-2'
      )}
    end        

  end  

end