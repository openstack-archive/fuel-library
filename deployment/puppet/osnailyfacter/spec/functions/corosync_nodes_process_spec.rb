require 'spec_helper'

describe 'corosync_nodes_process' do

  let(:corosync_nodes) do
    {
        'node-1.foo.bar' => {
            'id' => '20',
            'ip' => '1.2.3.4',
        },
        'node-44.qux' => {
            'id' => '130',
            'ip' => '33.3.3.5',
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
        'ids' => %w(10 20 30 130),
        'ips' => %w(2.2.3.4 1.2.3.4 33.2.3.4 33.3.3.5),
    }
  end

  it 'should exist' do
    is_expected.not_to be_nil
  end

  it 'should return processed corosync_nodes hash' do
    is_expected.to run.with_params(corosync_nodes).and_return(corosync_nodes_processed)
  end

end
