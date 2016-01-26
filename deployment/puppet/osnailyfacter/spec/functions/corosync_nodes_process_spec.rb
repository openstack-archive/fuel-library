require 'spec_helper'

describe 'the corosync_nodes process function' do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  let(:corosync_nodes) do
    {
      'node-1.foo.bar' => {
        'id' => '20',
        'ip' => '1.2.3.4',
        },
      'node-2' => {
        'id' => '10',
        'ip' => '2.2.3.4',
        },
      'node-33.qux' => {
        'id' => '30',
        'ip' => '33.2.3.4',
        },
    }
  end

  let(:corosync_nodes_processed) do
    {
      'ids' => ['20', '10', '30'],
      'ips' => ['1.2.3.4', '2.2.3.4', '33.2.3.4']
    }
  end

  it 'should exist' do
    expect(
        Puppet::Parser::Functions.function('corosync_nodes_process')
    ).to eq('function_corosync_nodes_process')
  end

  it 'should return processed corosync_nodes hash' do
    expect(
        scope.function_corosync_nodes_process([corosync_nodes])
    ).to eq corosync_nodes_processed
  end

end
