Facter.add("generate_fuel_key") do
  setcode do
    begin
      File.read('/etc/fuel-uuid').chomp
    rescue
      nil
    end
  end
end
