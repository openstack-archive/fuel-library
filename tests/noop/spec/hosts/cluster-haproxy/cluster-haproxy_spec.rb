require 'spec_helper'
require 'shared-examples'
manifest = 'cluster-haproxy/cluster-haproxy.pp'

describe manifest do

  before(:each) do
    Noop.puppet_function_load :is_pkg_installed
    MockFunction.new(:is_pkg_installed) do |function|
      allow(function).to receive(:call).and_return false
    end
  end

  shared_examples 'catalog' do
    let(:endpoints) do
      Noop.hiera_hash('network_scheme', {}).fetch('endpoints', {})
    end

    unless Noop.hiera('external_lb', false)

      it "should delcare cluster::haproxy with correct other_networks" do
        expect(subject).to contain_class('cluster::haproxy').with(
          'other_networks' => Noop.puppet_function('direct_networks', endpoints),
        )
      end

      it "should setup rsyslog configuration for haproxy" do
        expect(subject).to contain_file('/etc/rsyslog.d/haproxy.conf')
      end

      if Noop.hiera('colocate_haproxy', true)
        it "should contain management vip colocation with haproxy" do
          expect(subject).to contain__pcmk_colocation('vip_management-with-haproxy').with(
            'first'  => 'p_haproxy',
            'second' => 'vip__management',
          )
        end
        it "should contain public vip colocation with haproxy" do
          expect(subject).to contain__pcmk_colocation('vip_public-with-haproxy').with(
            'first'  => 'p_haproxy',
            'second' => 'vip__public',
          )
        end
    end
  end
  test_ubuntu_and_centos manifest
end
