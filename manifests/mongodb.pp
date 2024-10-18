# @summary Setup MongoDB service as part of replica set
#
# Setup MongoDB service as part of replica set
#
# @example
#   include grayloginstall::mongodb
class grayloginstall::mongodb (
  String  $graylog_password,

  Boolean $manage_open_files_limit = true,
  Boolean $manage_selinux          = false,
  String  $version                 = $grayloginstall::params::mongodb_version,
  Optional[Array[Stdlib::IP::Address]]
          $bind_ip                 = undef,
  Optional[Integer[0,1]]
          $repo_sslverify          = undef,

  # MongoDB replica set
  Boolean $setup_replica_set       = true,
  String  $replica_set_name        = $grayloginstall::params::mongodb_replset_name,
  Optional[Grayloginstall::MongoAddr]
          $replica_set_members     = undef,

  # Graylog MongoDB user
  String  $graylog_user            = $grayloginstall::params::mongodb_user,
  String  $graylog_database        = $grayloginstall::params::mongodb_database,
) inherits grayloginstall::params {
  include grayloginstall::cluster
  $cluster_discovery = $grayloginstall::cluster::mongo_discovery
  $cluster_bind_ip   = $grayloginstall::cluster::ipaddr
  $mongodb_port      = $grayloginstall::params::mongodb_port

  # parameter bind_ip has higher priority over cluster settings
  if $bind_ip and $bind_ip[0] {
    $config_bind_ip = $bind_ip
  }
  # IP address of network interface that belongs to subnet specified via grayloginstall::cluster::subnet
  # if subnet is not specified - default IP address (IP address of inerface that default route set to)
  # Undef if grayloginstall::cluster::fallback_default is false and cluster subnet is not specified
  elsif $cluster_bind_ip {
    $config_bind_ip = [$cluster_bind_ip]
  }
  else {
    # fallback to module default
    $config_bind_ip = $grayloginstall::params::mongodb_bind_ip
  }

  # https://docs.mongodb.com/master/tutorial/install-mongodb-on-red-hat/
  #
  # https://docs.mongodb.com/master/reference/ulimit/
  if $manage_open_files_limit {
    rlimit { '*/nofile':
      ensure => present,
      value  => 65535,
    }
  }

  # if $manage_selinux and $::facts['selinux'] {
  # TODO: https://docs.mongodb.com/master/tutorial/install-mongodb-on-red-hat/#configure-selinux
  # }

  class { 'mongodb::globals':
    version             => $version,
    manage_package_repo => true,
    use_enterprise_repo => false,
  }

  if $repo_sslverify {
    Yumrepo <| title == 'mongodb' |> {
      sslverify => $repo_sslverify,
    }
  }

  # file resource to not purge repo in case if /etc/yum.repos.d are managed with purge => true
  file { '/etc/yum.repos.d/mongodb.repo':
    mode => '0600',
  }

  systemd::dropin_file { 'mongod.service.d/limits.conf':
    filename => 'limits.conf',
    unit     => 'mongod.service',
    content  => file('grayloginstall/system/etc/systemd/system/mongod.service.limits'),
    before   => Class['mongodb::server'],
  }

  if $setup_replica_set {
    # The minimum recommended configuration for a replica set is a three member replica set with three data-bearing
    # members: one primary and two secondary members.
    # see https://docs.mongodb.com/manual/core/replica-set-members/
    if $replica_set_members and $replica_set_members.length >= 3 {
      $replset_members = $replica_set_members
    }
    elsif $cluster_discovery and $cluster_discovery.length >= 3 {
      $replset_members = $cluster_discovery
    }
    else {
      $replset_members = []
    }

    if $replset_members[0] {
      $replset_members_port = $replset_members.map |$member| { "${member}:${mongodb_port}" }

      $config_replset = {
        replset         => $replica_set_name,
        replset_members => $replset_members_port,
      }
    }
    else {
      $config_replset = {}
    }
  }
  else {
    $replset_members = []
    $config_replset = {}
  }

  class { 'mongodb::client': }
  class { 'mongodb::server':
    bind_ip => $config_bind_ip,
    *       => $config_replset,
  }

  # MongoDB user
  mongodb_user { $graylog_user:
    ensure        => present,
    password_hash => mongodb_password($graylog_user, $graylog_password),
    database      => $graylog_database,
    roles         => ['readWrite', 'dbAdmin'],
    require       => Class['mongodb::server'],
  }

  # TODO: https://docs.mongodb.com/manual/tutorial/convert-secondary-into-arbiter/

  Class['mongodb::globals'] -> Class['mongodb::client']
  Class['mongodb::globals'] -> Class['mongodb::server']
}
