require 'spec_helper'

describe 'vmware::ceilometer::simple' do
  let(:title) { 'cluster1' }

  let(:params) { { :index => '0' } }

  context 'on debian' do
    let(:facts) { { :osfamily => 'debian' } }

    it 'should create directory /etc/ceilometer/ceilometer-compute.d/' do
      should contain_file('/etc/ceilometer/ceilometer-compute.d').with({
        'ensure' => 'directory',
        'owner'  => 'ceilometer',
        'group'  => 'ceilometer',
        'mode'   => '0750',
      })
    end

    context 'file /etc/ceilometer/ceilometer-compute.d/vmware-0.conf' do
      it 'must be created' do
        should contain_file('/etc/ceilometer/ceilometer-compute.d/vmware-0.conf').with({
          'owner'  => 'ceilometer',
          'group'  => 'ceilometer',
          'mode'  => '0600',
        })
      end

      it 'must configure "host" parameter properly' do
        should contain_file('/etc/ceilometer/ceilometer-compute.d/vmware-0.conf').with_content(
          /^\s*host=0$/
        )
      end
    end

    it 'should contain default parameter for ceilometer-compute-vmware' do
      should contain_file('/etc/default/ceilometer-compute-vmware-0').with_content(
        %r{NOVA_COMPUTE_OPTS='--config-file=/etc/ceilometer/ceilometer.conf --config-file=/etc/ceilometer/ceilometer-compute.d/vmware-0.conf'}
      )
    end

    it 'should contain UpStart script' do
      should contain_file('/etc/init/ceilometer-compute-vmware.conf')
    end
  end

  context 'on redhat' do
    let(:facts) { { :osfamily => 'redhat' } }

    it 'must create custom init.d script for ceilometer-compute' do
      should contain_file('/etc/init.d/openstack-ceilometer-compute-vmware')
    end

    it 'must create file with default parameters for ceilometer-compute' do
      should contain_file('/etc/sysconfig/openstack-ceilometer-compute-vmware-0').with_content(
        %r{OPTIONS='--config-file=/etc/ceilometer/ceilometer.conf --config-file=/etc/ceilometer/ceilometer-compute.d/vmware-0.conf'}
      )
    end

    it 'must create symlink to custom init.d script' do
      should contain_file('/etc/init.d/openstack-ceilometer-compute-vmware-0').with({
        'ensure' => 'link',
        'target' => '/etc/init.d/openstack-ceilometer-compute-vmware'
      })
    end
  end
end
