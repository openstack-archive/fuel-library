require 'spec_helper'
require 'shared-examples'
manifest = 'ssl/ssl_keys_saving.pp'

describe manifest do
  test_ubuntu_and_centos manifest
end

