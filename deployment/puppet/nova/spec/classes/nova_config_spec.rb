require 'spec_helper'

describe 'nova::config' do

  let :params do
    { :nova_config => {
        'DEFAULT/foo' => { 'value'  => 'fooValue' },
        'DEFAULT/bar' => { 'value'  => 'barValue' },
        'DEFAULT/baz' => { 'ensure' => 'absent' }
      },
      :nova_paste_api_ini => {
        'DEFAULT/foo2' => { 'value'  => 'fooValue' },
        'DEFAULT/bar2' => { 'value'  => 'barValue' },
        'DEFAULT/baz2' => { 'ensure' => 'absent' }
      }
    }
  end

  it 'configures arbitrary nova configurations' do
    is_expected.to contain_nova_config('DEFAULT/foo').with_value('fooValue')
    is_expected.to contain_nova_config('DEFAULT/bar').with_value('barValue')
    is_expected.to contain_nova_config('DEFAULT/baz').with_ensure('absent')
  end

  it 'configures arbitrary nova api-paste configurations' do
    is_expected.to contain_nova_paste_api_ini('DEFAULT/foo2').with_value('fooValue')
    is_expected.to contain_nova_paste_api_ini('DEFAULT/bar2').with_value('barValue')
    is_expected.to contain_nova_paste_api_ini('DEFAULT/baz2').with_ensure('absent')
  end
end
