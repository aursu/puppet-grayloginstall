# @summary A short summary of the purpose of this defined type.
#
# A description of what this defined type does
#
# @example
#   grayloginstall::mongodb_host { 'namevar': }
define grayloginstall::mongodb_host (
  Stdlib::Fqdn
          $hostname     = $::facts['fqdn'],
  Stdlib::IP::Address
          $ip           = $::facts['networking']['ip'],
  Stdlib::Unixpath
          $hosts_target = '/etc/graylog/mongodb.hosts',
  String  $cluster_name = 'graylog',
) {
  $mongodb_hostname = "mongodb.${hostname}"
  host { $mongodb_hostname:
    ensure => present,
    ip     => $ip,
    target => $hosts_target,
  }
}
