# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @example
#   include grayloginstall::web
class grayloginstall::web  (
  String  $server_name,
  Boolean $ssl                 = false,
  Optional[String]
          $ssl_cert            = undef,
  Optional[String]
          $ssl_key             = undef,
  Stdlib::IP::Address
          $http_bind_ip         = $grayloginstall::params::http_bind_ip,
  Integer $http_bind_port       = $grayloginstall::params::http_bind_port,
) inherits grayloginstall::params
{
  include nginx

  # Nginx upstream
  $nginx_upstream_members = {
    "${http_bind_ip}:${http_bind_port}" => {
      server => $http_bind_ip,
      port   => $http_bind_port,
    }
  }

  # if SSL enabled - both certificate and key must be provided
  if $ssl and !($ssl_cert and $ssl_key) {
    fail('SSL certificate path and/or SSL private key path not provided')
  }

  # Nginx upstream for GrayLog Web
  nginx::resource::upstream { 'graylog-web':
    members => $nginx_upstream_members,
  }

  # lint:ignore:140chars
  # type=AVC msg=audit(1554992273.902:517150): avc:  denied  { name_connect } for  pid=2581 comm="nginx" dest=5000 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:commplex_main_port_t:s0 tclass=tcp_socket permissive=0
  # lint:endignore
  # Was caused by:
  # The boolean httpd_can_network_connect was set incorrectly.
  # Description:
  # Allow httpd to can network connect
  # Allow access by executing:
  # setsebool -P httpd_can_network_connect 1
  if $::facts['os']['selinux'] {
    selinux::boolean { 'httpd_can_network_connect': }
  }

  # if SSL enabled - use SSL only
  if $ssl {
    $listen_port = 443
  }
  else {
    $listen_port = 80
  }

  # setup GitLab nginx main config
  # https://docs.docker.com/registry/recipes/nginx/
  nginx::resource::server { 'graylog-http':
    ssl                  => $ssl,
    http2                => $ssl,
    ssl_cert             => $ssl_cert,
    ssl_key              => $ssl_key,
    ssl_session_timeout  => '1d',
    ssl_cache            => 'shared:SSL:50m',
    ssl_session_tickets  => false,
    ssl_protocols        => 'TLSv1.2',
    ssl_ciphers          => 'ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256', # lint:ignore:140chars
    ssl_stapling         => true,
    ssl_stapling_verify  => true,
    listen_ip            => '*',
    listen_port          => $listen_port,
    server_name          => [
      $server_name,
    ],
    # HSTS Config
    # https://www.nginx.com/blog/http-strict-transport-security-hsts-and-nginx/
    add_header           => {
      'Strict-Transport-Security' => 'max-age=15768000',
    },
    # Individual nginx logs for this GitLab vhost
    access_log           => '/var/log/nginx/graylog.access_log',
    format_log           => 'combined',
    error_log            => '/var/log/nginx/graylog.error_log',
    locations            => {
      '/'                  => {
        proxy            => 'http://graylog-web',
        proxy_set_header => [
          # required for docker client's sake
          'Host                 $http_host',
          'X-Forwarded-Host     $host',
          'X-Forwarded-Server   $host',
          'X-Forwarded-For      $proxy_add_x_forwarded_for',
          'X-Graylog-Server-URL http://$server_name/',
        ],
      },
    },
    use_default_location => false,
  }
}
