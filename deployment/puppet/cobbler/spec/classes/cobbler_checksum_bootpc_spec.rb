require 'spec_helper'

describe 'cobbler::checksum_bootpc' do

  let(:default_params) { {
  } }

  shared_examples_for 'cobbler::checksum_bootpc configuration' do
    let :params do
      default_params
    end


    context 'with default params' do
      let :params do
        default_params.merge!({})
      end

      it 'configures with the default params' do
        if facts[:operatingsystem] == 'RedHat'
          save_location = '/etc/sysconfig/iptables'
        elsif facts[:operatingsystem] == 'Debian'
          save_location = '/etc/iptables.rules'
        end
      end
    end
  end

  context 'on Debian platforms' do
    let :facts do
      @default_facts.merge({ :osfamily => 'Debian',
        :operatingsystem => 'Debian',
      })
    end

    it_configures 'cobbler::checksum_bootpc configuration'
  end

  context 'on RedHat platforms' do
    let :facts do
      @default_facts.merge({ :osfamily => 'RedHat',
        :operatingsystem => 'RedHat',
      })
    end

    it_configures 'cobbler::checksum_bootpc configuration'
  end

end

