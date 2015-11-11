require 'spec_helper'

describe 'extend_kopts' do

  it 'number args' do
    is_expected.to run.with_params('foo').and_raise_error(Puppet::ParseError, "extend_kopts(): wrong number of arguments - 1, must be 2")
  end

  it { should run.with_params("biosdevname=0 ifnames=1 rd.luks.uuid=30 panic=15 quiet debug udev.log-priority=2 systemd.gpt_auto=1","console=ttyS0,9600 panic=60 boot=live toram fetch=http://127.0.0.1:8080/active_bootstrap/root.squashfs biosdevname=0").and_return("console=ttyS0,9600 panic=15 boot=live toram fetch=http://127.0.0.1:8080/active_bootstrap/root.squashfs biosdevname=0 ifnames=1 rd.luks.uuid=30 quiet debug udev.log-priority=2 systemd.gpt_auto=1") }

end
