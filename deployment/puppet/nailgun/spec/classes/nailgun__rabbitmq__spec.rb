require 'spec_helper'

describe 'nailgun::rabbitmq', :type => :class do
  context 'on supported platform' do
    let(:facts) {{
      :osfamily               => 'Debian',
      :lsbdistid              => 'Ubuntu',
      :operatingsystem        => 'Ubuntu',
      :operatingsystemrelease => '14.04',
    }}
    context 'with default parameters' do
      describe 'declares rabbitmq class' do
        it {
          should contain_class('rabbitmq')
        }
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
