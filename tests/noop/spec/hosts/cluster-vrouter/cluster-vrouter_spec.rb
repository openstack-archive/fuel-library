require 'spec_helper'
require 'shared-examples'
manifest = 'cluster-vrouter/cluster-vrouter.pp'

describe manifest do

  shared_examples 'catalog' do
    let(:endpoints) do
      Noop.hiera('network_scheme', {}).fetch('endpoints', {})
    end

    let(:scope) do
      scope = PuppetlabsSpec::PuppetInternals.scope
      Puppet::Parser::Functions.autoloader.loadall unless scope.respond_to? :function_derect_networks
      scope
    end

    let(:other_networks) do
      scope.function_direct_networks [endpoints]
    end

    it "should delcare cluster::vrouter_ocf with correct other_networks" do
      expect(subject).to contain_class('cluster::vrouter_ocf').with(
        'other_networks' => other_networks,
      )
    end

  end

  test_ubuntu_and_centos manifest
end

