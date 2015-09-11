require 'spec_helper'
require 'yaml'
require 'zlib'

describe 'create_dnsmasq_dhcp_ranges' do

  it 'refuses String' do
    is_expected.to run.with_params('foo').\
      and_raise_error(Puppet::ParseError, /Should pass admin networks hash as a parameter/)
  end

end
