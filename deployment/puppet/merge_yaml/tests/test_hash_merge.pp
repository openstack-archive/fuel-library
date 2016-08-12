hash_fragment { 'test1' :
  hash_name => 'test',
  priority  => '01',
  data      => { 'a' => '1' },
}

hash_fragment { 'test2' :
  hash_name => 'test',
  priority  => '02',
  data      =>  { 'b' => '1' },
}

hash_fragment { 'test3' :
  hash_name => 'test',
  priority  => '03',
  data      =>  { 'a' => '2' },
}

hash_fragment { 'test4' :
  hash_name => 'test',
  priority  => '04',
  data      =>  { 'b' => '2' },
}

hash_fragment { 'test5' :
  hash_name => 'other',
  priority  => '05',
  data      =>  { 'a' => '3' },
}

hash_merge { '/tmp/test.yaml' :
  hash_name => 'test',
}
