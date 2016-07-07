class osnailyfacter::build_image(
  $data = undef,
){

  if $data == undef {
    $data = loadjson('/tmp/provision.json')
  }
  $cluster_id = $data['cluster']['id']

  if $data['ironic']['enabled'] == 'true' {
    $package_list = join(['--package openssh-server', 'ntp', 'fuel-agent', 'ubuntu-minimal', 'live-boot', 'wget', 'live-boot-initramfs-tools', 'squashfs-tools', 'linux-firmware', 'msmtp-mta', 'hpsa-dkms', 'i40e-dkms', 'linux-firmware-nonfree', 'xz-utils', 'linux-headers-generic'], ' --package ')
    $ssh_auth_file = "/var/lib/fuel/keys/${cluster_id}/ironic/ironic.pub"
    $ssh_params = "--root-ssh-authorized-file ${ssh_auth_file}"

    $out_dir = "/var/www/nailgun/bootstrap/ironic/${cluster_id}/"
    $out_params = "--output-dir ${out_dir}"

    $extra_params = "--extra-dir /usr/share/ironic-fa-bootstrap-configs/ --no-compress --no-default-extra-dirs --no-default-packages"
    $log_params = '--log-file /var/log/fuel-ironic-bootstrap-image-build.log'

    exec { 'generate_image_with_ironic':
      command => "fuel-bootstrap build ${package_list} ${ssh_params} ${out_params} ${extra_params} ${log_params}"
      path    => ['/bin', '/usr/bin'],
      unless  => "test -e /var/www/nailgun/bootstrap/ironic/${cluster_id}/vmlinuz",

  } else {
    $build_dir = '--image_build_dir /var/lib/fuel/ibp'
    $log_params = "--log-file /var/log/fuel-agent-env-${cluster_id}.log"
    $extra_params = '--data_driver nailgun_build_image'

    $repos_data = $data['repo_setup']['repos']
    $repos = "'repos': ${repos_data}"
    $image_data = $data['provision']['image_data']
    $images = "'image_data': ${image_data}"
    $codename_data = $data['provision']['codename']
    $codename = "'codename': ${codename_data}"
    $output_dir = "'output': /var/www/nailgun/targetimages"
    $packages_data = split($data['provision']['packages'], '\n')
    $packages = "'packages': ${packages_data}"
    $input_data = "--input_data '{${repos}, ${images}, ${codename}, ${output_dir}, ${packages}}'"

    exec { 'generate_image_with_fuel':
      command => "fa_build_image ${build_dir} ${log_params} ${extra_params} ${input_data}"
      path    => ['/bin', '/usr/bin'],
      unless  => "test -e /var/www/nailgun/bootstrap/ironic/${cluster_id}/vmlinuz",
  }

}
