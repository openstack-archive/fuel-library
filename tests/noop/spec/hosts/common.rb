shared_examples 'compute_service_common' do

  let (:nova_compute_service_name) do
    if facts[:osfamily] == 'RedHat'
      'openstack-nova-compute'
    elsif facts[:osfamily] == 'Debian'
      'nova-compute'
    else
      fail "Osfamily: #{facts[:osfamily]} is not supported!"
    end
  end

  it do
    is_expected.not_to contain_service(nova_compute_service_name).with(:ensure => 'running')
  end

end

shared_examples 'common' do
  include_examples 'compute_service_common' unless Noop.current_spec_is? 'roles/enable_compute'
end
