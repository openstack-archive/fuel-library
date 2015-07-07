require 'spec_helper'

describe 'swift::storage::disk' do
  # TODO add more unit tests

  let :title do
    'sdb'
  end

  let :params do
    {
      :base_dir     => '/dev',
      :mnt_base_dir => '/srv/node',
      :byte_size    => '1024',
    }
  end

  it { is_expected.to contain_swift__storage__xfs('sdb').with(
    :device       => '/dev/sdb',
    :mnt_base_dir => '/srv/node',
    :byte_size    => '1024',
    :subscribe    => 'Exec[create_partition_label-sdb]',
    :loopback     =>  false
  ) }

end
