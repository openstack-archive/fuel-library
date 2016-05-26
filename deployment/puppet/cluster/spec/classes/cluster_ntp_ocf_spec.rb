require 'spec_helper'

describe 'cluster::ntp_ocf' do

  shared_examples_for 'ntp_ocf configuration' do

    it 'configures with the default params' do
      should contain_class('cluster::ntp_ocf')
      should contain_pacemaker_resource('p_ntp').with_before(["Pacemaker_colocation[ntp-with-vrouter-ns]", "Service[ntp]"]) 
      should contain_pacemaker_colocation('ntp-with-vrouter-ns').with(
        :ensure => 'present',
        :score  => 'INFINITY',
        :first  => 'clone_p_vrouter', 
        :second => 'clone_p_ntp')
    end
  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian',
        :operatingsystem => 'Debian', }
    end

    it_configures 'ntp_ocf configuration'
  end

end

