class nova::limits ($limits = {})
{

  $default_limits = {
    'POST' => 10,
    'POST_SERVERS' => 50,
    'PUT' => 10,
    'GET' => 3,
    'DELETE' => 100,
  }

  $merged_limits = merge($default_limits, $limits)

  $post_limit=$merged_limits[POST]
  $put_limit=$merged_limits[PUT]
  $get_limit=$merged_limits[GET]
  $delete_limit=$merged_limits[DELETE]
  $post_servers_limit=$merged_limits[POST_SERVERS]

  Package<| title == 'nova-common' |> -> Nova_paste_api_ini<| |>

  nova_paste_api_ini {'filter:ratelimit/limits': value => "(POST, \"*\", .*, ${post_limit}, MINUTE);(POST, \"*/servers\", ^/servers, ${post_servers_limit}, DAY);(PUT, \"*\", .*, ${put_limit}, MINUTE);(GET, \"*changes-since*\", .*changes-since.*, ${get_limit}, MINUTE);(DELETE, \"*\", .*, ${delete_limit}, MINUTE)"}
}
