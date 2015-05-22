require 'spec_helper'
require 'shared-examples'
manifest = 'ssl/ssl_add_trust_chain.pp'

describe manifest do
  test_ubuntu_and_centos manifest
end

