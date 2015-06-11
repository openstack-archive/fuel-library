require 'spec_helper'

describe 'openstacklib::policy' do

  let :params do
    {
      :policies => {
        'foo' => {
          'file_path' => '/etc/nova/policy.json',
          'key'       => 'context_is_admin',
          'value'     => 'foo:bar'
        }
      }
    }
  end

  it 'configures the proper policy' do
    is_expected.to contain_openstacklib__policy__base('foo').with(
      :file_path => '/etc/nova/policy.json',
      :key       => 'context_is_admin',
      :value     => 'foo:bar'
    )
  end

end
