Facter.add("generate_fuel_key") do
  setcode do
    Facter::Util::Resolution.exec('uuidgen')
  end
end