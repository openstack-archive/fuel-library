require 'spec_helper'

describe 'host_hash_deleted_nodes' do
  it { is_expected.not_to be_nil }

  it 'failes if the nodes hash is not a hash' do
     is_expected.to run.with_params('node1', 'node2').and_raise_error /should be a Hash/
  end

  let(:hosts_hash) do
    {
        'node-1' => { :ensure => 'present' },
        'node-2' => { :ensure => 'present' },
        'node-3' => { :ensure => 'present' },
    }
  end

  let(:deleted_nodes) do
    %w(node-2 node-4 node-5)
  end

  let(:result) do
    {
        'node-1' => { :ensure => 'present' },
        'node-2' => { :ensure => 'present' },
        'node-3' => { :ensure => 'present' },
        'node-4' => { :ensure => 'absent' },
        'node-5' => { :ensure => 'absent' },
    }
  end

  it 'adds deleted nodes to the hosts hash' do
    is_expected.to run.with_params(hosts_hash, deleted_nodes).and_return(result)
  end
end
