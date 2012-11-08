require 'spec_helper'

describe 'swift::storage::filter::recon' do
  let :title do
    'dummy'
  end

  let :facts do
    {
      :concat_basedir => '/var/lib/puppet/concat'
    }
  end

  let :pre_condition do
    'class { "concat::setup": }
     concat { "/etc/swift/dummy-server.conf": }'
  end

  let :fragment_file do
    "/var/lib/puppet/concat/_etc_swift_dummy-server.conf/fragments/35_swift_recon_dummy"
  end

  describe 'when passing default parameters' do
    it 'should build the fragment with correct content' do
      verify_contents(subject, fragment_file,
        [
          '[filter:recon]',
          'use = egg:swift#recon',
          'recon_cache_path = /var/cache/swift'
        ]
      )
    end
  end

  describe 'when overriding default parameters' do
    let :params do
      {
        :cache_path => '/some/other/path'
      }
    end
    it 'should build the fragment with correct content' do
      verify_contents(subject, fragment_file,
        [
          '[filter:recon]',
          'use = egg:swift#recon',
          'recon_cache_path = /some/other/path'
        ]
      )
    end
  end

end
