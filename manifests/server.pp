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
# @param mongodb_addr
#   MongoDB conneectionn address. If provided than has higher priority than self-managed instance of MongoDB
#   (see `mongodb_bind_ip` and `mongodb_replset_members`)
#
# @param manage_mongodb
#   Boolean flag whether to manage own MongoDB instance or not
#
# @param mongodb_bind_ip
#   Array of IP addresses. If provided, MongoDB will bind to these addresses only.
#   If not provided MongoDB will bind to address that reside in `cluster_network` if specified.
#   Otherwise it will fallback to default (see `grayloginstall::params`)
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
# @param http_bind_cluster
#   Whether to bind WEB interface to cluster network (if provided - see `cluster_network`) or to fallback to `http_bind_external`
#   (see below). If specified both http_bind_ip and http_bind_cluster than http_bind_ip option has higher priority
#
# @param http_bind_external
#   Whether to bind WEB interface to external network (if provided - see `external_network`) or to fallback to default server IP
#   (see $::facts['networking']['ip']). If specified  http_bind_ip or http_bind_cluster than these options have higher priority
#
class grayloginstall::server (
  String  $root_password,
  String  $mongodb_password,

  String[64]
          $password_secret,
  String  $package_version             = $grayloginstall::params::graylog_version,
  String  $major_version               = $grayloginstall::params::graylog_major,

  Optional[Grayloginstall::MongoAddr]
          $mongodb_addr                = undef,
  Optional[String]
          $mongodb_conn_replset_name   = undef,

  # TODO: MongoDB authentication
  String  $mongodb_user                = $grayloginstall::params::mongodb_user,
  String  $mongodb_database            = $grayloginstall::params::mongodb_database,

  Boolean $manage_mongodb              = true,

  Optional[Array[Stdlib::IP::Address]]
          $mongodb_bind_ip             = undef,

  # https://docs.graylog.org/en/3.3/pages/configuration/multinode_setup.html#mongodb-replica-set
  Boolean $setup_replica_set           = true,
  Optional[Grayloginstall::MongoAddr]
          $mongodb_replset_members     = undef,
  Optional[String]
          $mongodb_replset_name        = $grayloginstall::params::mongodb_replset_name,

  Boolean $manage_elastic              = true,

  Optional[Grayloginstall::NetworkHost]
          $elastic_network_host        = undef,
  Optional[Array[Stdlib::IP::Address]]
          $elastic_seed_hosts          = undef,
  Boolean $elastic_master_only         = false,

  Boolean $manage_java                 = true,

  Optional[Integer[0,1]]
          $repo_sslverify              = undef,

  Optional[Stdlib::IP::Address]
          $cluster_network             = undef,
  Optional[Stdlib::IP::Address]
          $external_network            = undef,

  Optional[Stdlib::IP::Address]
          $http_bind_ip                = undef,
  Integer $http_bind_port              = $grayloginstall::params::http_bind_port,
  Boolean $http_bind_cluster           = true,
  Boolean $http_bind_external          = true,

  Boolean $enable_web                  = true,
  Optional[Stdlib::Fqdn]
          $http_server                 = undef,
  Boolean $http_secure                 = false,
  Optional[String]
          $http_ssl_cert               = undef,
  Optional[String]
          $http_ssl_key                = undef,

  String  $cluster_name                = $grayloginstall::params::cluster_name,
  Boolean $is_master                   = false,
) inherits grayloginstall::params
{
  $elastic_port = $grayloginstall::params::elastic_port
  $mongodb_port = $grayloginstall::params::mongodb_port

  if $manage_java {
    include grayloginstall::java
  }

  # define cluster settings
  class { 'grayloginstall::cluster':
    cluster_name    => $cluster_name,
    subnet          => $cluster_network,
    external_subnet => $external_network,
  }

  $cluster_bind_ip = $grayloginstall::cluster::ipaddr

  if $manage_mongodb {
    class { 'grayloginstall::mongodb':
      repo_sslverify      => $repo_sslverify,
      bind_ip             => $mongodb_bind_ip,
      replica_set_name    => $mongodb_replset_name,
      replica_set_members => $mongodb_replset_members,

      graylog_user        => $mongodb_user,
      graylog_password    => $mongodb_password,
      graylog_database    => $mongodb_database,
    }

    $graylog_mongodb_bind_ip = $grayloginstall::mongodb::config_bind_ip
    $graylog_mongodb_replset_members = $grayloginstall::mongodb::replset_members
  }
  else {
    $graylog_mongodb_bind_ip = []
    $graylog_mongodb_replset_members = []
  }

  if $manage_elastic {
    class { 'grayloginstall::elastic':
      network_host         => $elastic_network_host,
      discovery_seed_hosts => $elastic_seed_hosts,
      master_only          => $elastic_master_only,
    }

    $config_elastic_seed_hosts = $grayloginstall::elastic::graylog_elasticsearch_hosts
  }
  else {
    $config_elastic_seed_hosts = []
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
  elsif $http_bind_cluster and $cluster_bind_ip {
    $config_http_bind_ip = $cluster_bind_ip
  }
  elsif $http_bind_external {
    $config_http_bind_ip = $grayloginstall::cluster::extip
  }
  else {
    $config_http_bind_ip = $grayloginstall::params::http_bind_ip
  }

  $http_bind_address = "${config_http_bind_ip}:${http_bind_port}"

  if $enable_web and $http_server {
    # dont't remove slash from `http_external_uri`
    # com.github.joschi.jadconfig.ValidationException: "http_external_uri" must end with a slash ("/")
    if $http_secure {
      $http_external_uri = "https://${http_server}/"
    }
    else {
      $http_external_uri = "http://${http_server}/"
    }

    $config_http_external_uri = {
      'http_external_uri'  => $http_external_uri,
    }
  }
  else {
    $config_http_external_uri = {}
  }

  if $config_elastic_seed_hosts[0] {
    $elasticsearch_url_list = $config_elastic_seed_hosts.reduce([]) |$memo, $seed_host| {
                            $memo + [ "http://${seed_host}:${elastic_port}" ]
                          }

    $config_elasticsearch_hosts = {
                                    'elasticsearch_hosts' => join($elasticsearch_url_list, ',')
                                  }
  }
  else {
    $config_elasticsearch_hosts = {}
  }

  # mongodb_uri
  if $mongodb_addr and $mongodb_addr[0] {
    $mongodb_uri_addr_list = $mongodb_addr
    if $mongodb_addr.length >= 3 {
      $mongodb_uri_replset = $mongodb_conn_replset_name
    }
    else {
      $mongodb_uri_replset = undef
    }
  }
  elsif $manage_mongodb {
    if $graylog_mongodb_replset_members[0] {
      $mongodb_uri_addr_list = $graylog_mongodb_replset_members
      $mongodb_uri_replset = $mongodb_replset_name
    }
    else {
      $mongodb_uri_addr_list = $graylog_mongodb_bind_ip
      $mongodb_uri_replset = undef
    }
  }
  else {
    fail('Either mongodb_addr list should be provided with MongoDB address(es) or own Mongo instance management enabled')
  }

  $mongodb_uri_pw = grayloginstall::mongo_password($mongodb_password)
  $access_string = "${mongodb_user}:${mongodb_uri_pw}"

  # https://docs.mongodb.com/manual/reference/connection-string/
  # TODO: https://docs.mongodb.com/manual/reference/connection-string/#connections-connection-options
  if $mongodb_uri_addr_list[1] {
    $mongodb_hosts_list = $mongodb_uri_addr_list.reduce([]) |$memo, $mongo_host| {
                            $memo + [ "${mongo_host}:${mongodb_port}" ]
                          }
    $mongodb_hosts = join($mongodb_hosts_list, ',')

    if $mongodb_uri_replset {
      # Replica Set
      $config_mongodb_uri = { 'mongodb_uri' => "mongodb://${access_string}@${mongodb_hosts}/${mongodb_database}?replicaSet=${mongodb_uri_replset}" }
    }
    else {
      $config_mongodb_uri = { 'mongodb_uri' => "mongodb://${access_string}@${mongodb_hosts}/${mongodb_database}" }
    }
  }
  else {
    $mongodb_hosts = $mongodb_uri_addr_list[0]
    # Standalone
    $config_mongodb_uri = { 'mongodb_uri' => "mongodb://${access_string}@${mongodb_hosts}:${mongodb_port}/${mongodb_database}" }
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
                        $config_http_external_uri +
                        $config_elasticsearch_hosts +
                        $config_mongodb_uri,
  }

  Package['graylog-server'] ~>Service['graylog-server']

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
