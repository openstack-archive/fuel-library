# ROLE: primary-controller
# ROLE: controller
# ROLE: controller

require 'spec_helper'
require 'shared-examples'
manifest = 'cluster-vrouter/cluster-vrouter.pp'

describe manifest do

  shared_examples 'catalog' do
    let(:endpoints) do
      Noop.hiera_hash('network_scheme', {}).fetch('endpoints', {})
    end

    it "should delcare cluster::vrouter_ocf with correct other_networks" do
      expect(subject).to contain_class('cluster::vrouter_ocf').with(
        'other_networks' => Noop.puppet_function('direct_networks', endpoints),
      )
    end

  end

  test_ubuntu_and_centos manifest
end

