require 'spec_helper'
require 'pathname'
require_relative '../puppet_modules'

describe PuppetModules do
  let(:root_dir) { Pathname.new('/virtual_root') }
  let(:puppet_dir) { root_dir + Pathname.new('puppet') }
  let(:mod1) { puppet_dir + Pathname.new('mod1') }
  let(:mod2) { puppet_dir + Pathname.new('mod2') }

  before(:each) do
    allow(subject).to receive(:module_names).and_return(%w(mod1 mod2))
    allow(subject).to receive(:dir_path_root).and_return(root_dir)
    allow(subject).to receive(:librarian_puppet_installed?).and_return(true)
    allow(subject).to receive(:librarian_puppet_simple?).and_return(true)
    allow(subject).to receive(:git_present?).and_return(true)
    allow(subject).to receive(:file_exists?).with(mod1).and_return(true)
    allow(subject).to receive(:file_exists?).with(mod2).and_return(true)

    allow(subject).to receive(:output)
  end

  let(:puppet_files) do
    [
        root_dir + Pathname.new('Puppetfile'),
        root_dir + Pathname('puppet/openstack_tasks/Puppetfile'),
    ]
  end

  it 'can get the list of external modules' do
    allow(subject).to receive(:module_names).and_call_original
    allow(subject).to receive(:file_read).with(puppet_files[0]).and_return("mod 'mod_c'; mod 'mod_b'")
    allow(subject).to receive(:file_read).with(puppet_files[1]).and_return("mod 'mod_a'")
    expect(subject.module_names).to eq (%w(mod_a mod_b mod_c))
  end

  it 'can output the list of modules' do
    list = <<-eof
mod1
mod2
    eof
    expect(subject).to receive(:output).with(list)
    subject.modules_list
  end

  it 'can compress external puppet modules' do
    cmd = 'tar -czpvf /virtual_root/puppet_modules.tgz mod1 mod2'
    expect(subject).to receive(:run_inside_directory).with(puppet_dir, cmd).and_return(true)
    subject.modules_compress
  end

  it 'can restore external puppet modules' do
    cmd = 'tar -xpvf /virtual_root/puppet_modules.tgz'
    allow(subject).to receive(:file_exists?).with(root_dir + Pathname.new('puppet_modules.tgz')).and_return(true)
    expect(subject).to receive(:run_inside_directory).with(puppet_dir, cmd).and_return(true)
    expect(subject).to receive(:modules_remove)
    subject.modules_restore
  end

  it 'can view the status of modules' do
    cmd1 = 'librarian-puppet git_status --path=/virtual_root/puppet --puppetfile=/virtual_root/Puppetfile'
    cmd2 = 'librarian-puppet git_status --path=/virtual_root/puppet --puppetfile=/virtual_root/puppet/openstack_tasks/Puppetfile'
    expect(subject).to receive(:run_inside_directory).with(root_dir, cmd1)
    expect(subject).to receive(:run_inside_directory).with(root_dir, cmd2)
    subject.modules_status
  end

  it 'can update modules' do
    cmd1 = 'librarian-puppet update --path=/virtual_root/puppet --puppetfile=/virtual_root/Puppetfile'
    cmd2 = 'librarian-puppet update --path=/virtual_root/puppet --puppetfile=/virtual_root/puppet/openstack_tasks/Puppetfile'
    expect(subject).to receive(:run_inside_directory).with(root_dir, cmd1)
    expect(subject).to receive(:run_inside_directory).with(root_dir, cmd2)
    expect(subject).to receive(:modules_install)
    subject.modules_update
  end

  it 'can reset modules' do
    expect(subject).to receive(:git_present?).with(mod1).and_return(true)
    expect(subject).to receive(:git_present?).with(mod2).and_return(false)
    expect(subject).to receive(:file_remove).with(mod2)
    expect(subject).to receive(:run_inside_directory).with(mod1, 'git reset --hard').and_return(true)
    expect(subject).to receive(:run_inside_directory).with(mod1, 'git clean -f -d -x').and_return(true)
    expect(subject).to receive(:modules_install)
    subject.modules_reset
  end

  it 'can install modules' do
    cmd1 = 'librarian-puppet install --path=/virtual_root/puppet --puppetfile=/virtual_root/Puppetfile'
    cmd2 = 'librarian-puppet install --path=/virtual_root/puppet --puppetfile=/virtual_root/puppet/openstack_tasks/Puppetfile'
    expect(subject).to receive(:run_inside_directory).with(root_dir, cmd1)
    expect(subject).to receive(:run_inside_directory).with(root_dir, cmd2)
    expect(subject).to receive(:write_module_versions_file)
    subject.modules_install
  end

  it 'can remove modules' do
    expect(subject).to receive(:file_remove).with(mod1)
    expect(subject).to receive(:file_remove).with(mod2)
    subject.modules_remove
  end

  it 'can reinstall modules' do
    expect(subject).to receive(:modules_remove)
    expect(subject).to receive(:modules_install)
    subject.modules_reinstall
  end

end
