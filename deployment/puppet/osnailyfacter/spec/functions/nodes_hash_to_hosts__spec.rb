require 'spec_helper'

describe 'nodes_hash_to_hosts' do
let(:nodes_hash) do
  YAML.load <<-eof
---
    node-1:
      fqdn: node-1.test.domain.local
      name: node-1
      network_roles:
        admin/pxe: 10.77.0.3
        mgmt/vip: 192.168.0.2
        nova/migration: 192.168.28.1
      node_roles:
        - ceph-osd
        - primary-controller
      user_node_name: CNT1
    node-2:
      fqdn: node-2.test.domain.local
      name: node-2
      network_roles:
        admin/pxe: 10.77.0.4
        mgmt/vip: 192.168.0.3
        nova/migration: 192.168.28.2
      node_roles:
        - ceph-osd
        - controller
      user_node_name: CNT2
    node-3:
      fqdn: node-3.test.domain.local
      name: node-3
      network_roles:
        admin/pxe: 10.77.0.5
        mgmt/vip: 192.168.0.4
        nova/migration: 192.168.28.3
      node_roles:
        - ceph-osd
        - controller
      user_node_name: CNT3
    node-4:
      fqdn: node-4.test.domain.local
      name: node-4
      network_roles:
        admin/pxe: 10.77.0.6
        mgmt/vip: 192.168.0.5
        nova/migration: 192.168.28.4
      node_roles:
        - ceph-osd
        - compute
      user_node_name: CO1
    node-5:
      fqdn: node-5.test.domain.local
      name: node-5
      network_roles:
        admin/pxe: 10.77.0.7
        mgmt/vip: 192.168.0.6
        nova/migration: 192.168.28.5
      node_roles:
        - ceph-osd
        - compute
      user_node_name: CO2
eof
end


  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  subject do
    function_name = Puppet::Parser::Functions.function(:nodes_hash_to_hosts)
    scope.method(function_name)
  end

  context "nodes_hash_to_hosts" do

    it 'should exist' do
      subject == Puppet::Parser::Functions.function(:nodes_hash_to_hosts)
    end

    it 'should throw an error if called without args' do
      should run.with_params().and_raise_error(Puppet::ParseError)
    end

    it "run.with_params(nodes_hash, 'mgmt/api', true, '', '')" do
      should run.with_params(nodes_hash, 'mgmt/vip', true, '', '').and_return({
        "node-1.test.domain.local" => {:ip=>"192.168.0.2", :host_aliases=>["node-1"]},
        "node-2.test.domain.local" => {:ip=>"192.168.0.3", :host_aliases=>["node-2"]},
        "node-3.test.domain.local" => {:ip=>"192.168.0.4", :host_aliases=>["node-3"]},
        "node-4.test.domain.local" => {:ip=>"192.168.0.5", :host_aliases=>["node-4"]},
        "node-5.test.domain.local" => {:ip=>"192.168.0.6", :host_aliases=>["node-5"]}
      })
    end

    it "run.with_params([nodes_hash, 'nova/migration', false, 'xxx-', '-zzz'])" do
      should run.with_params(nodes_hash, 'nova/migration', false, 'xxx-', '-zzz').and_return({
        "xxx-node-1.test.domain.local-zzz" => {:ip=>"192.168.28.1"},
        "xxx-node-2.test.domain.local-zzz" => {:ip=>"192.168.28.2"},
        "xxx-node-3.test.domain.local-zzz" => {:ip=>"192.168.28.3"},
        "xxx-node-4.test.domain.local-zzz" => {:ip=>"192.168.28.4"},
        "xxx-node-5.test.domain.local-zzz" => {:ip=>"192.168.28.5"}
      })
    end

    # it do
    #   should run.with_params('192.168.2.0/24', 10).and_return('192.168.2.0/24,metric:10')
    # end

    # it do
    #   should run.with_params('192.168.2.0/24', 'xxx').and_return('192.168.2.0/24')
    # end

  end
end
# vim: set ts=2 sw=2 et