require 'spec_helper'

describe 'openstacklib::policy::base' do

  let :title do
    'nova-contest_is_admin'
  end

  let :params do
    {:file_path => '/etc/nova/policy.json',
    :key       => 'context_is_admin',
    :value     => 'foo:bar'}
  end

  it 'configures the proper policy' do
    should contain_augeas('/etc/nova/policy.json-context_is_admin-foo:bar').with(
      'lens'    => 'Json.lns',
      'incl'    => '/etc/nova/policy.json',
      'changes' => 'set dict/entry[*][.="context_is_admin"]/string foo:bar'
    )
  end

end
