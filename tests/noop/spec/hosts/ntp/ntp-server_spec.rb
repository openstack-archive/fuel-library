require 'spec_helper'
require 'shared-examples'
manifest = 'ntp/ntp-server.pp'

describe manifest do

  shared_examples 'catalog' do
    let(:role) do
      Noop.hiera 'role'
    end

    let(:ntp_servers) do
      Noop.hiera 'external_ntp'
    end

    let(:servers) do
      ntp_servers['ntp_list'].split(',').compact.collect(&:strip)
    end

    it "should contain class ntp" do
      should contain_class('ntp').with(
        'servers' => servers,
      ).that_comes_before('Class[cluster::ntp_ocf]')
    end

    it "should contain class cluster::ntp_ocf" do
      should contain_class('cluster::ntp_ocf')
    end
  end

  test_ubuntu_and_centos manifest
end

