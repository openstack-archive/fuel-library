require 'spec_helper'
require 'shared-examples'
manifest = 'virtual_ips/public_vip_ping.pp'

shared_examples 'puppet catalogue' do

  it do
    expect(subject).to contain_cs_resource('ping_vip__public').with(
                           'ensure' => 'present',
                       )
  end

  it do
    expect(subject).to contain_service('ping_vip__public').with(
                           'provider' => 'pacemaker',
                           'ensure'   => 'running',
                           'enable'   => true,
                       )
  end

  it do
    expect(subject).to contain_cs_rsc_location('loc_ping_vip__public')
  end
end

describe manifest do
  test_ubuntu_and_centos manifest, true
end
