require 'spec_helper'

describe 'extend_kopts' do

  it 'number args' do
    is_expected.to run.with_params('foo').and_raise_error(Puppet::ParseError, "extend_kopts(): wrong number of arguments - 1, must be 2")
  end

  it { should run.with_params("biosdevname=0 ifnames=1 rd.luks.uuid=30 panic=15 quiet debug udev.log-priority=2 systemd.gpt_auto=1","console=ttyS0,9600 console=tty0 console=tty1 panic=60 boot=live toram fetch=http://127.0.0.1:8080/active_bootstrap/root.squashfs biosdevname=0").and_return("biosdevname=0 ifnames=1 rd.luks.uuid=30 panic=15 quiet debug udev.log-priority=2 systemd.gpt_auto=1 console=ttyS0,9600 console=tty0 console=tty1 boot=live toram fetch=http://127.0.0.1:8080/active_bootstrap/root.squashfs") }

  it 'should merge options with the same key using first argument as high priority source' do
    should run.with_params("bios=0 rd.luks=30", "bios=1 rd.luks=20").and_return("bios=0 rd.luks=30")
  end

  it 'should combine unique options' do
    should run.with_params("biosdevname=0 quit", "biosdevname=1 debug").and_return("biosdevname=0 quit debug")
  end

  it 'should properly merge options contain key-value separator' do
    should run.with_params("abc=def=123 debug", "abc=ttt=44 quit").and_return("abc=def=123 debug quit")
  end

  it 'should save options order' do
    should run.with_params("zx=123 ar bh=test", "").and_return("zx=123 ar bh=test")
  end

  it 'should use default options if new are not present' do
    should run.with_params("", "ff=11 quit ko=12").and_return("ff=11 quit ko=12")
  end

  it 'should merge options with multiple values' do
    should run.with_params("c=ttyS0,9600 c=tty0", "c=tty3 ff=11").and_return("c=ttyS0,9600 c=tty0 ff=11")
  end

end
