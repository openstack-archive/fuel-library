require 'spec_helper'

describe 'default_provider_for' do
  let(:facts) {{
      :osfamily => 'Debian',
      :operatingsystem => 'Ubuntu',
      :kernel => 'Linux',
      :l23_os => 'ubuntu',
      :l3_fqdn_hostname => 'stupid_hostname',
  }}

  it { is_expected.not_to eq(nil) }
  it { is_expected.to run.with_params('file').and_return('posix') }
end