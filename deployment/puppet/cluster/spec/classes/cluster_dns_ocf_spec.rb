require 'spec_helper'

describe 'cluster::dns_ocf' do

  let(:default_params) do
    {}
  end

  shared_examples_for 'dns_ocf configuration' do
    let :params do
      default_params
    end

    it 'configures with the params params' do
      should contain_class('cluster::dns_ocf')

      should contain_pcmk_resource('p_dns')

      should contain_pcmk_colocation('dns-with-vrouter-ns').with(
        :ensure => 'present',
        :score  => 'INFINITY',
        :first  => 'clone_p_vrouter',
        :second => 'clone_p_dns'
      ).that_requires('Pcmk_resource[p_dns]')

      should contain_service('p_dns').with(
        :name       => 'p_dns',
        :enable     => true,
        :ensure     => 'running',
        :hasstatus  => true,
        :hasrestart => true,
        :provider   => 'pacemaker',
      ).that_requires('Pcmk_colocation[dns-with-vrouter-ns]')
    end
  end

  on_supported_os(supported_os: supported_os).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts.merge common_facts }
      it_configures 'dns_ocf configuration'
    end
  end

end

