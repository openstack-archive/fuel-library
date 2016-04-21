require 'spec_helper'

describe 'fuel::rabbitmq', :type => :class do
  context 'on supported platform' do
    let(:facts) {{
      :osfamily               => 'Debian',
      :lsbdistid              => 'Ubuntu',
      :operatingsystem        => 'Ubuntu',
      :operatingsystemrelease => '14.04',
    }}
    context 'with default parameters' do
      describe 'declares rabbitmq class' do
        it { should contain_class('rabbitmq').with(
          :repos_ensure      => false,
          :package_provider  => 'yum',
          :service_ensure    => 'running',
          :delete_guest_user => true,
          :config_cluster    => false,
          :cluster_nodes     => [],
          :config_stomp      => true,
          :ssl               => false,
          :tcp_keepalive     => true,
        )}
      end
      describe 'and sets appropriate log_level configuration for rabbitmq' do
        it {
          should contain_file('rabbitmq.config').with({
            'content' => /{log_levels, \[{connection,debug,info,error}\]},/,
          })
        }
      end
    end
  end
end
