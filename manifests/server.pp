# @summary A short summary of the purpose of this class
#
# @example
#   include grayloginstall::server
#
# @param http_bind_ip
#   IP part of elasticsearch setting http_bind_address
#   Default is 127.0.0.1
#   See https://docs.graylog.org/en/3.2/pages/configuration/web_interface.html
#
# @param http_bind_port
#   Port part of elasticsearch setting http_bind_address
#   Default is 9000
#   See https://docs.graylog.org/en/3.2/pages/configuration/web_interface.html
#
# @param http_external_uri
#   The public URI of Graylog which will be used by the Graylog web interface to communicate with the Graylog REST API. Graylog
#   web interface.
#
class grayloginstall::server (
  String  $root_password,
  String[64]
          $password_secret,
  String  $major_version        = '3.3',
  String  $package_version      = '3.3.0',

  Boolean $manage_mongodb       = true,
  Optional[Array[Stdlib::IP::Address]]
          $mongodb_bind_ip      = undef,

  Boolean $manage_elastic       = true,
  Optional[Grayloginstall::NetworkHost]
          $elastic_network_host = undef,
  Optional[Array[Stdlib::IP::Address]]
          $elastic_seed_hosts   = undef,

  Boolean $manage_java          = true,

  Optional[Integer[0,1]]
          $repo_sslverify       = undef,

  Boolean $is_master            = false,
  Stdlib::IP::Address
          $http_bind_ip         = '127.0.0.1',
  Integer $http_bind_port       = 9000,
  Optional[Stdlib::HTTPUrl]
          $http_external_uri    = undef,
  String  $cluster_name         = $grayloginstall::params::cluster_name,
  Optional[Stdlib::IP::Address]
          $cluster_network      = undef,
) inherits grayloginstall::params
{
  if $manage_java {
    include grayloginstall::java
  }

  # define cluster settings
  class { 'grayloginstall::cluster':
    cluster_name => $cluster_name,
    subnet       => $cluster_network,
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
    }
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

  $http_bind_address = "${http_bind_ip}:${http_bind_port}"

  if $http_external_uri {
    $external_uri_config = {
      'http_external_uri'  => $http_external_uri,
    }
  }
  else {
    $external_uri_config = {}
  }

  class { 'graylog::server':
    package_version => $package_version,
    # https://docs.graylog.org/en/3.2/pages/getting_started/configure.html
    config          => {
      'password_secret'    => $password_secret,
      'root_password_sha2' => sha256($root_password),
      'is_master'          => $is_master,
      'http_bind_address'  => $http_bind_address,
    } + $external_uri_config,
  }
}
