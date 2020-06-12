# https://nginx.org/en/docs/ngx_core_module.html#error_log
type Grayloginstall::NetworkHost = Variant[
  Stdlib::IP::Address,
  Enum['_local_'],
  Enum['_site_'],
  Enum['_global_'],
  Pattern[/_[a-z0-9]+_/],
  Pattern[/_[a-z0-9]+:ipv[46]_/]
]
