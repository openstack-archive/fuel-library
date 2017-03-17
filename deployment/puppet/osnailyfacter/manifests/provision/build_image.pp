class osnailyfacter::provision::build_image(
  $data_file = '/tmp/provision.yaml',
){

  if $data_file == undef {
    $data = loadyaml('/tmp/provision.yaml')
  } else {
    $data = loadyaml($data_file)
  }
  $cluster_id = $data['cluster']['id']

  if $data['ironic']['enabled'] == true {
    # TODO(vsaienko): Use the same system packages for fuel image and ironic bootstrap, but exclude
    # not needed for ironic like nailgun-agent, etc...
    $ironic_packages = [
      'openssh-server',
      'ntp',
      'fuel-agent',
      'ubuntu-minimal',
      'live-boot',
      'wget',
      'live-boot-initramfs-tools',
      'squashfs-tools',
      'linux-firmware',
      'msmtp-mta',
      'i40e-dkms',
      'xz-utils',
      'linux-headers-generic',
    ]

    $package_list = join(prefix($ironic_packages, '--package '), ' ')
    $ssh_auth_file = "/var/lib/fuel/keys/${cluster_id}/ironic/ironic.pub"
    $ssh_params = "--root-ssh-authorized-file ${ssh_auth_file}"

    $out_dir = "/var/www/nailgun/bootstrap/ironic/${cluster_id}/"
    $out_params = "--output-dir ${out_dir}"

    $ironic_extra_params = "--extra-dir /usr/share/ironic-fa-bootstrap-configs/ --no-compress --no-default-extra-dirs --no-default-packages"
    $ironic_log_params = '--log-file /var/log/fuel-ironic-bootstrap-image-build.log'

    exec { 'generate_image_with_ironic':
      command => "fuel-bootstrap build ${package_list} ${ssh_params} ${out_params} ${ironic_extra_params} ${ironic_log_params}",
      path    => ['/bin', '/usr/bin'],
      timeout => 1800,
      unless  => "test -e /var/www/nailgun/bootstrap/ironic/${cluster_id}/vmlinuz",
    }

  }

  $build_dir = '--image_build_dir /var/lib/fuel/ibp'
  $log_params = "--log-file /var/log/fuel-agent-env-${cluster_id}.log"
  $extra_params = '--data_driver nailgun_build_image'

  exec { 'generate_image_with_fuel':
    command => "fa_build_image ${build_dir} ${log_params} ${extra_params} --input_data_file ${data_file}",
    path    => ['/bin', '/usr/bin'],
    timeout => 1800,
  }
}
