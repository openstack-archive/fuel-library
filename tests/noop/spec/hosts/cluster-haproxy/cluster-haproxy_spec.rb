require 'spec_helper'
require 'shared-examples'
manifest = 'cluster-haproxy/cluster-haproxy.pp'

describe manifest do
  shared_examples 'catalog' do
    let(:endpoints) do
      task.hiera_hash('network_scheme', {}).fetch('endpoints', {})
    end

    unless task.hiera('external_lb', false)

      it "should delcare cluster::haproxy with correct other_networks" do
        expect(subject).to contain_class('cluster::haproxy').with(
          'other_networks' => task.puppet_function('direct_networks', endpoints),
        )
      end

      it "should setup rsyslog configuration for haproxy" do
        expect(subject).to contain_file('/etc/rsyslog.d/haproxy.conf')
      end
    end
  end
  test_ubuntu_and_centos manifest
end
