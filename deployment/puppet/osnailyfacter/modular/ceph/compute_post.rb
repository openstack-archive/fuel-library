require File.join File.dirname(__FILE__), '../test_common.rb'

class CephComputePostTest < Test::Unit::TestCase
  def config
    '/etc/nova/nova.conf'
  end

  def ephemeral_enabled?
    TestCommon::Settings.lookup('storage', {}).fetch 'ephemeral_ceph', false
  end

  def test_nova_ceph_ephemeral_configured
    return unless ephemeral_enabled?
    assert TestCommon::Config.value?(config, 'libvirt/images_type', 'rbd'), 'No libvirt/images_type in nova.conf!'
    assert TestCommon::Config.value?(config, 'libvirt/inject_key', false), 'No libvirt/inject_key in nova.conf!'
    assert TestCommon::Config.value?(config, 'libvirt/inject_partition', -2), 'No libvirt/inject_partition in nova.conf!'
    assert TestCommon::Config.value?(config, 'libvirt/images_rbd_pool', 'compute'), 'No libvirt/images_rbd_pool in nova.conf!'
  end

  def test_nova_ceph_compute_configured
    assert TestCommon::Config.value?(config, 'libvirt/rbd_user', 'compute'), 'No libvirt/rbd_user in nova.conf!'
    assert TestCommon::Config.has_line?(config, /^rbd_secret_uuid=[\w\-]*$/), 'No rbd_secret_uuid in nova.conf!'
  end
end
