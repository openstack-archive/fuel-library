require 'spec_helper'

describe 'cluster::haproxy::rsyslog' do
  let(:default_params) { {
    :log_file => '/var/log/haproxy.log'
  } }

  shared_examples_for 'haproxy rsyslog configuration' do
    let :params do
      default_params
    end

    context 'with default parameters' do
      it 'should configure rsyslog for haproxy' do
        should contain_file('/etc/rsyslog.d/haproxy.conf')
      end
    end

  end

end
