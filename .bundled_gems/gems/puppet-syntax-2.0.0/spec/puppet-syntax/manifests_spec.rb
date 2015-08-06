require 'spec_helper'
require 'puppet'

describe PuppetSyntax::Manifests do
  let(:subject) { PuppetSyntax::Manifests.new }

  it 'should expect an array of files' do
    expect { subject.check(nil) }.to raise_error(/Expected an array of files/)
  end

  it 'should return nothing from a valid file' do
    files = fixture_manifests('pass.pp')
    output, has_errors = subject.check(files)

    expect(output).to eq([])
    expect(has_errors).to eq(false)
  end

  it 'should return an error from an invalid file' do
    files = fixture_manifests('fail_error.pp')
    output, has_errors = subject.check(files)

    expect(output.size).to eq(1)
    expect(output[0]).to match(/Syntax error at .*:3$/)
    expect(has_errors).to eq(true)
  end

  it 'should return a warning from an invalid file' do
    files = fixture_manifests('fail_warning.pp')
    output, has_errors = subject.check(files)

    expect(output.size).to eq(2)
    expect(output[0]).to match(/Unrecognised escape sequence '\\\[' .* at line 3$/)
    expect(output[1]).to match(/Unrecognised escape sequence '\\\]' .* at line 3$/)
    expect(has_errors).to eq(true)
  end

  it 'should ignore warnings about storeconfigs' do
    files = fixture_manifests('pass_storeconfigs.pp')
    output, has_errors = subject.check(files)

    expect(output).to eq([])
    expect(has_errors).to eq(false)

  end

  it 'should read more than one valid file' do
    files = fixture_manifests(['pass.pp', 'pass_storeconfigs.pp'])
    output, has_errors = subject.check(files)

    expect(output).to eq([])
    expect(has_errors).to eq(false)
  end

  it 'should continue after finding an error in the first file' do
    files = fixture_manifests(['fail_error.pp', 'fail_warning.pp'])
    output, has_errors = subject.check(files)

    expect(output.size).to eq(3)
    expect(output[0]).to match(/Syntax error at '\}' .*:3$/)
    expect(output[1]).to match(/Unrecognised escape sequence '\\\[' .* at line 3$/)
    expect(output[2]).to match(/Unrecognised escape sequence '\\\]' .* at line 3$/)
    expect(has_errors).to eq(true)
  end

  describe 'deprecation notices' do
    # These tests should fail in Puppet 4, but we need to wait for the release
    # before we'll know exactly how to test it.
    if Puppet::Util::Package.versioncmp(Puppet.version, '3.7') >= 0
      context 'on puppet >= 3.7' do
        it 'should return deprecation notices as warnings' do
          files = fixture_manifests('deprecation_notice.pp')
          output, has_errors = subject.check(files)

          expect(has_errors).to eq(false)
          expect(output.size).to eq(2)
          expect(output[0]).to match(/The use of 'import' is deprecated/)
          expect(output[1]).to match(/Deprecation notice:/)
        end
      end
    elsif Puppet::Util::Package.versioncmp(Puppet.version, '3.5') >= 0
      context 'on puppet 3.5 and 3.6' do
        it 'should return deprecation notices as warnings' do
          files = fixture_manifests('deprecation_notice.pp')
          output, has_errors = subject.check(files)

          expect(has_errors).to eq(false)
          expect(output.size).to eq(1)
          expect(output[0]).to match(/The use of 'import' is deprecated/)
        end
      end
    elsif Puppet::Util::Package.versioncmp(Puppet.version, '3.5') < 0
      context 'on puppet < 3.5' do
        it 'should not print deprecation notices' do
          files = fixture_manifests('deprecation_notice.pp')
          output, has_errors = subject.check(files)

          expect(output).to eq([])
          expect(has_errors).to eq(false)
        end
      end
    end
  end

  describe 'future_parser' do
    context 'future_parser = false (default)' do
      it 'should fail without setting future option to true on future manifest' do
        expect(PuppetSyntax.future_parser).to eq(false)

        files = fixture_manifests(['future_syntax.pp'])
        output, has_errors = subject.check(files)

        expect(output.size).to eq(1)
        expect(output[0]).to match(/Syntax error at '='; expected '\}' .*:2$/)
        expect(has_errors).to eq(true)
      end
    end

    context 'future_parser = true' do
      before(:each) {
        PuppetSyntax.future_parser = true
      }

      if Puppet::Util::Package.versioncmp(Puppet.version, '3.2') >= 0
        context 'Puppet >= 3.2' do
          it 'should pass with future option set to true on future manifest' do
            files = fixture_manifests(['future_syntax.pp'])
            output, has_errors = subject.check(files)

            expect(output).to eq([])
            expect(has_errors).to eq(false)
          end
        end
        context 'Puppet >= 3.7' do
          # Certain elements of the future parser weren't added until 3.7
          if Puppet::Util::Package.versioncmp(Puppet.version, '3.7') >= 0
            it 'should fail on what were deprecation notices in the non-future parser' do
              files = fixture_manifests('deprecation_notice.pp')
              output, has_errors = subject.check(files)

              expect(output.size).to eq(1)
              expect(output[0]).to match(/Node inheritance is not supported/)
              expect(has_errors).to eq(true)
            end
          end
        end
      else
        context 'Puppet < 3.2' do
          it 'should return an error that the parser option is not supported' do
            files = fixture_manifests(['future_syntax.pp'])
            output, has_errors = subject.check(files)

            expect(output.size).to eq(1)
            expect(output[0]).to match("Attempt to assign a value to unknown configuration parameter :parser")
            expect(has_errors).to eq(true)
          end
        end
      end
    end
  end

end
