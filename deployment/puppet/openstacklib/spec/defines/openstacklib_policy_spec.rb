require 'spec_helper'

describe 'openstacklib::policy::base' do

  let :title do
    'nova-contest_is_admin'
  end

  let :params do
    {:file_path => '/etc/nova/policy.json',
    :key       => 'context_is_admin or owner',
    :value     => 'foo:bar'}
  end

  it 'configures (modifies) the proper policy' do
    is_expected.to contain_augeas('/etc/nova/policy.json-context_is_admin or owner-foo:bar').with(
      'lens'    => 'Json.lns',
      'incl'    => '/etc/nova/policy.json',
      'changes' => 'set dict/entry[*][.="context_is_admin or owner"]/string "foo:bar"',
      'require' => 'Augeas[/etc/nova/policy.json-context_is_admin or owner-foo:bar-add]'
    )
  end

  it 'configures (adds) the proper policy' do
    is_expected.to contain_augeas('/etc/nova/policy.json-context_is_admin or owner-foo:bar-add').with(
      'lens'    => 'Json.lns',
      'incl'    => '/etc/nova/policy.json',
      'changes' => [
          'set dict/entry[last()+1] "context_is_admin or owner"',
          'set dict/entry[last()]/string "foo:bar"'
      ],
      'onlyif' => 'match dict/entry[*][.="context_is_admin or owner"] size == 0'
    )
  end

end

