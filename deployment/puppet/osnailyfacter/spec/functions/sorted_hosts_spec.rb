require 'spec_helper'

describe 'sorted_hosts' do
  let(:input) do
    {
        'host-2' => '192.168.0.1',
        'host-1' => '192.168.0.2',
        'host-20' => '192.168.0.10',
        'host-10' => '192.168.0.20',
    }
  end

  it { is_expected.not_to be_nil }

  it 'should require a nodes to ip hash' do
    is_expected.to run.with_params('a').and_raise_error /should be a host name to IP mapping/
  end

  it { is_expected.to run.with_params(input).and_return(%w(host-1 host-2 host-10 host-20)) }

  it { is_expected.to run.with_params(input, 'ip').and_return(%w(192.168.0.2 192.168.0.1 192.168.0.20 192.168.0.10)) }

  it { is_expected.to run.with_params(input, 'host', 'ip').and_return(%w(host-2 host-1 host-20 host-10)) }

  it { is_expected.to run.with_params(input, 'ip', 'ip').and_return(%w(192.168.0.1 192.168.0.2 192.168.0.10 192.168.0.20)) }
end
