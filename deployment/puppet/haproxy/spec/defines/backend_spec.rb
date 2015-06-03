require 'spec_helper'

describe 'haproxy::backend' do
  let(:pre_condition) { 'include haproxy' }
  let(:facts) do
    {
      :ipaddress      => '1.1.1.1',
      :osfamily       => 'Redhat',
      :concat_basedir => '/dne',
    }
  end

  context "when no options are passed" do
    let(:title) { 'bar' }

    it { should contain_concat__fragment('bar_backend_block').with(
      'order'   => '20-bar-00',
      'target'  => '/etc/haproxy/haproxy.cfg',
      'content' => "\nbackend bar\n  balance  roundrobin\n  option  tcplog\n  option  ssl-hello-chk\n"
    ) }
  end

  # C9953
  context "when a listen is created with the same name" do
    let(:title) { 'apache' }
    let(:pre_condition) do
      "haproxy::listen { 'apache': ports => '443', }"
    end

    it 'should raise error' do
      expect { subject }.to raise_error Puppet::Error, /discovered with the same name/
    end
  end

  # C9956 WONTFIX
end
