require 'time'
require 'pp'
Puppet::Parser::Functions::newfunction(:echo, :doc => <<-EOS
Output the inspected value of the variable and its type.
Example:
$a = 'test'
$b = ["1", "2", "3"]
$c = {"a"=>"1", "b"=>"2"}
$d = true
$f = { "b" => { "b" => [1,2,3], "c" => true, "d" => { 'x' => 'y' }}, 'x' => 'y', 'z' => [1,2,3,4,5,6]}
$g = 12345
echo($a, 'My string')
echo($b, 'My array')
echo($c, 'My hash')
echo($d, 'My boolean')
echo($e, 'My undef')
echo($f, 'My structure')
echo($g) # no comment here

2015/02/10 21:53:11.067: My string (String) "test"
2015/02/10 21:53:11.067: My array (Array) ["1", "2", "3"]
2015/02/10 21:53:11.067: My hash (Hash) {"a"=>"1", "b"=>"2"}
2015/02/10 21:53:11.067: My boolean (TrueClass) true
2015/02/10 21:53:11.068: My undef (String) ""
2015/02/10 21:53:11.068: My structure (Hash) {"b"=>{"b"=>["1", "2", "3"], "c"=>true, "d"=>{"x"=>"y"}},
 "x"=>"y",
 "z"=>["1", "2", "3", "4", "5", "6"]}
2015/02/10 21:53:11.068: (String) "12345"
EOS
) do |argv|
  value = argv[0]
  comment = argv[1]
  timestamp = Time.now.strftime("%Y/%m/%d %H:%M:%S.%3N")
  message = "(#{value.class}) #{value.pretty_inspect}"
  if comment
    message = "#{comment} #{message}"
  end
  message = "#{timestamp}: #{message}"
  puts message
end

