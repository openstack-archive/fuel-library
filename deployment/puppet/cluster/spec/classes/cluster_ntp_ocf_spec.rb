require 'spec_helper'

describe 'cluster::ntp_ocf' do

  shared_examples_for 'ntp_ocf configuration' do

    it 'configures with the default params' do
      service_name = platform_params[:service_name]
      should contain_class('cluster::ntp_ocf')
      should contain_pcmk_resource("p_#{service_name}").with_before(["Pcmk_colocation[ntp-with-vrouter-ns]", "Service[#{service_name}]"])
      should contain_pcmk_colocation("ntp-with-vrouter-ns").with(
        :ensure => 'present',
        :score  => 'INFINITY',
        :first  => 'clone_p_vrouter',
        :second => "clone_p_#{service_name}")
    end
  end

  on_supported_os(supported_os: supported_os).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts.merge(common_facts) }

      let :platform_params do
        if facts[:osfamily] == 'Debian'
          {
              :service_name => 'ntp'
          }
        else
          {
              :service_name => 'ntpd'
          }
        end
      end

      it_configures 'ntp_ocf configuration'
    end
  end

end

