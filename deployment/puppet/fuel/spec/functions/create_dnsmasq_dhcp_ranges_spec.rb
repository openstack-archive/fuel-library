require 'spec_helper'

describe 'create_dnsmasq_dhcp_ranges' do

  it 'refuses String' do
    is_expected.to run.with_params('foo').\
      and_raise_error(Puppet::ParseError, /Should pass list of hashes as a parameter/)
  end

end
