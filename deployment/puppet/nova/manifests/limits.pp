class nova::limits (
  $limits = { "POST" => 10,
 "POST_SERVERS" => 50,
 "PUT" => 10, "GET" => 3,
 "DELETE" => 100 }
)

{

$post_limit=$limits[POST]
$put_limit=$limits[PUT]
$get_limit=$limits[GET]
$delete_limit=$limits[DELETE]
$post_servers_limit=$limits[POST_SERVERS]

  Package<| title == 'nova-common' |> -> Nova_paste_api_ini<| |>

nova_paste_api_ini {"filter:ratelimit/limits": value => "(POST, \"*\", .*, $post_limit, MINUTE);(POST, \"*/servers\", ^/servers, $post_servers_limit, DAY);(PUT, \"*\", .*, $put_limit, MINUTE);(GET, \"*changes-since*\", .*changes-since.*, $get_limit, MINUTE);(DELETE, \"*\", .*, $delete_limit, MINUTE)"}

}


