require 'spec_helper'

describe 'l23network::l2::patch', :type => :define do
  let(:title) { 'Spec for l23network::l2::port' }
  let(:facts) { {
    :osfamily => 'Debian',
    :operatingsystem => 'Ubuntu',
    :kernel => 'Linux',
    :l23_os => 'ubuntu',
    :l3_fqdn_hostname => 'stupid_hostname',
  } }

  context 'Just a patch between two bridges' do
    let(:params) do
      {
        :bridges => ['br1', 'br2'],
      }
    end

    it do
      should compile
    end

    it do
      should contain_l23_stored_config('p_br1-0').only_with({
        'use_ovs' => nil,
        'method'  => nil,
        'ipaddr'  => nil,
        'gateway' => nil,
        'onboot'  => true,
        'bridge'  => ['br1', 'br2'],
        'jacks'   => ['p_br1-0', 'p_br2-1']
      })
    end

    it do
      should contain_l2_patch('patch__br1--br2').only_with({
        'ensure'  => 'present',
        'use_ovs' => nil,
        'bridges' => ['br1', 'br2'],
      }).that_requires('L23_stored_config[p_br1-0]')
    end
  end

  context 'Patch, which has jumbo frames' do
    let(:params) do
      {
        :bridges => ['br1', 'br2'],
        :mtu     => 9000,
      }
    end

    it do
      should compile
      should contain_l23_stored_config('p_br1-0').with({
        'bridge'  => ['br1', 'br2'],
        'jacks'   => ['p_br1-0', 'p_br2-1'],
        'mtu'     => 9000,
      })
      should contain_l2_patch('patch__br1--br2').with({
        'ensure'  => 'present',
        'mtu'     => 9000,
        'bridges' => ['br1', 'br2'],
      }).that_requires('L23_stored_config[p_br1-0]')
    end
  end

  context 'Patch, which has vendor-specific properties' do
    let(:params) do
      {
        :bridges         => ['br1', 'br2'],
        :vendor_specific => {
            'aaa' => '111',
            'bbb' => {
                'bbb1' => 1111,
                'bbb2' => ['b1','b2','b3']
            },
        },
      }
    end

    it do
      should compile
      should contain_l23_stored_config('p_br1-0').with({
        'bridge'          => ['br1', 'br2'],
        'jacks'           => ['p_br1-0', 'p_br2-1'],
        'vendor_specific' => {
            'aaa' => '111',
            'bbb' => {
                'bbb1' => 1111,
                'bbb2' => ['b1','b2','b3']
            },
        },
      })
      should contain_l2_patch('patch__br1--br2').with({
        'ensure'  => 'present',
        'bridges' => ['br1', 'br2'],
        'vendor_specific' => {
            'aaa' => '111',
            'bbb' => {
                'bbb1' => 1111,
                'bbb2' => ['b1','b2','b3']
            },
        },
      }).that_requires('L23_stored_config[p_br1-0]')
    end
  end


end
# vim: set ts=2 sw=2 et