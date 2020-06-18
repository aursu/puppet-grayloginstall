# @summary A short summary of the purpose of this class
#
# @example
#   include grayloginstall::server
#
# @param root_password
#   Root password to pass to SHA2 function in order to set up `root_password_sha2` (Graylog)
#
# @param password_secret
#   Secret that is used for password encryption and salting (Graylog)
#
# @param http_bind_ip
#   IP part of graylog setting `http_bind_address` (it has higher priority than `http_bind_external`)
#   Default is 127.0.0.1
#   See https://docs.graylog.org/en/3.2/pages/configuration/web_interface.html
#
# @param http_bind_port
#   Port part of graylog setting http_bind_address
#   Default is 9000
#   See https://docs.graylog.org/en/3.2/pages/configuration/web_interface.html
#
# @param http_external_uri
#   The public URI of Graylog which will be used by the Graylog web interface to communicate with the Graylog REST API. Graylog
#   web interface.
#
# @param external_network
#   In case of private and public network assigned to server (or multiple networks) - it is possible to specify external
#   network to bind on WEB interface (see http_bind_external)
#
# @param http_bind_external
#   Whether to bind WEB interface to external network (if provided - see `external_network`) or to fallback to default server IP
#   (see $::facts['networking']['ip']). If specified both http_bind_ip and http_bind_external than http_bind_ip has higher
#   priority
#
class grayloginstall::server (
  String  $root_password,
  String[64]
          $password_secret,
  String  $package_version      = $grayloginstall::params::graylog_version,
  String  $major_version        = $grayloginstall::params::graylog_major,

  Boolean $manage_mongodb       = true,

  Optional[
    Array[
      Variant[
        Stdlib::IP::Address,
        Stdlib::Fqdn
      ]
    ]
  ]       $mongodb_bind_ip      = undef,

  Boolean $manage_elastic       = true,

  Optional[Grayloginstall::NetworkHost]
          $elastic_network_host = undef,
  Optional[Array[Stdlib::IP::Address]]
          $elastic_seed_hosts   = undef,
  Boolean $elastic_master_only  = false,

  Boolean $manage_java          = true,

  Optional[Integer[0,1]]
          $repo_sslverify       = undef,

  Optional[Stdlib::IP::Address]
          $cluster_network      = undef,
  Optional[Stdlib::IP::Address]
          $external_network     = undef,

  Optional[Stdlib::IP::Address]
          $http_bind_ip         = undef,
  Integer $http_bind_port       = $grayloginstall::params::http_bind_port,
  Boolean $http_bind_external   = true,

  Boolean $enable_web           = true,
  Optional[Stdlib::Fqdn]
          $http_server          = undef,
  Boolean $http_secure          = false,
  Optional[String]
          $http_ssl_cert        = undef,
  Optional[String]
          $http_ssl_key         = undef,

  String  $cluster_name         = $grayloginstall::params::cluster_name,
  Boolean $is_master            = false,
) inherits grayloginstall::params
{
  $elastic_port = $grayloginstall::params::elastic_port

  if $manage_java {
    include grayloginstall::java
  }

  # define cluster settings
  class { 'grayloginstall::cluster':
    cluster_name    => $cluster_name,
    subnet          => $cluster_network,
    external_subnet => $external_network,
  }

  if $manage_mongodb {
    class { 'grayloginstall::mongodb':
      repo_sslverify => $repo_sslverify,
      bind_ip        => $mongodb_bind_ip,
    }
  }

  if $manage_elastic {
    class { 'grayloginstall::elastic':
      network_host         => $elastic_network_host,
      discovery_seed_hosts => $elastic_seed_hosts,
      master_only          => $elastic_master_only,
    }

    if $elastic_seed_hosts and $elastic_seed_hosts[0] {
      $elastic_discovery_seed_hosts = $elastic_seed_hosts
    }
    else {
      $elastic_discovery_seed_hosts = $grayloginstall::elastic::config_discovery_seed_hosts
    }
  }
  else {
    $elastic_discovery_seed_hosts = []
  }

  # https://docs.graylog.org/en/3.3/pages/installation/os/centos.html
  class { 'graylog::repository':
    url     => "https://packages.graylog2.org/repo/el/stable/${major_version}/\$basearch/",
    version => $major_version,
  }

  if $repo_sslverify {
    Yumrepo <| title == 'graylog' |> {
      sslverify => $repo_sslverify,
    }
  }

  # file resource to not purge repo in case if /etc/yum.repos.d are managed with purge => true
  file { '/etc/yum.repos.d/graylog.repo':
    mode => '0600',
  }

  file { '/etc/graylog':
    ensure => directory,
    mode   => '0755',
  }

  if $http_bind_ip {
    $config_http_bind_ip = $http_bind_ip
  }
  elsif $http_bind_external {
    $config_http_bind_ip = $grayloginstall::cluster::extip
  }
  else {
    $config_http_bind_ip = $grayloginstall::params::http_bind_ip
  }

  $http_bind_address = "${config_http_bind_ip}:${http_bind_port}"

  if $enable_web and $http_server {
    if $http_secure {
      $http_external_uri = "https://${http_server}"
    }
    else {
      $http_external_uri = "http://${http_server}"
    }

    $http_external_uri_config = {
      'http_external_uri'  => $http_external_uri,
    }
  }
  else {
    $http_external_uri_config = {}
  }

  if $elastic_discovery_seed_hosts[0] {
    $elasticsearch_hosts = $elastic_discovery_seed_hosts.reduce([]) |$memo, $seed_host| {
                            $memo + [ "http://${seed_host}:${elastic_port}" ]
                          }

    $elasticsearch_hosts_config = {
                                    'elasticsearch_hosts' => join($elasticsearch_hosts, ',')
                                  }
  }
  else {
    $elasticsearch_hosts_config = {}
  }

  class { 'graylog::server':
    package_version => $package_version,
    # https://docs.graylog.org/en/3.2/pages/getting_started/configure.html
    config          => {
                          'password_secret'    => $password_secret,
                          'root_password_sha2' => sha256($root_password),
                          'is_master'          => $is_master,
                          'http_bind_address'  => $http_bind_address,
                        } +
                        $http_external_uri_config +
                        $elasticsearch_hosts_config,
  }

  # WEB interface (Nginx)
  if $enable_web and $http_server {
    class { 'grayloginstall::web':
      server_name    => $http_server,
      ssl            => $http_secure,
      ssl_cert       => $http_ssl_cert,
      ssl_key        => $http_ssl_key,
      http_bind_ip   => $config_http_bind_ip,
      http_bind_port => $http_bind_port,
    }
  }
}
