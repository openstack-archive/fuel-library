require 'spec_helper'
require 'shared-examples'
manifest = 'cluster-haproxy/cluster-haproxy.pp'

describe manifest do
  shared_examples 'catalog' do
    let(:endpoints) do
      Noop.hiera('network_scheme', {}).fetch('endpoints', {})
    end

    it "should delcare cluster::haproxy with correct other_networks" do
      expect(subject).to contain_class('cluster::haproxy').with(
        'other_networks' => Noop.puppet_function('direct_networks', endpoints),
      )
    end

  end
  test_ubuntu_and_centos manifest
end
