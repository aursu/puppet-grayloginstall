# grayloginstall

Installation of GrayLog on the server with all components (MongoDD and Elasticsearch)

#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with grayloginstall](#setup)
    * [What grayloginstall affects](#what-grayloginstall-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with grayloginstall](#beginning-with-grayloginstall)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Limitations - OS compatibility, etc.](#limitations)
5. [Development - Guide for contributing to the module](#development)

## Description

Installation of GrayLog on the server with all components (MongoDD and Elasticsearch)

## Setup

### What grayloginstall affects **OPTIONAL**

### Setup Requirements **OPTIONAL**

PuppetDB proper setup required for Cluster setup

### Beginning with grayloginstall


## Usage

```
  class { 'grayloginstall::server':
    root_password        => $root_password,
    password_secret      => $password_secret,
    mongodb_password     => $mongodb_password,
    elastic_seed_hosts   => $elastic_seed_hosts,
    elastic_network_host => $elastic_network_host,
    elastic_master_only  => $elastic_master_only,
    cluster_network      => $cluster_network,
    repo_sslverify       => 0,

    is_master            => $is_master,
    enable_web           => $enable_web,
    http_server          => $http_server,
  }
```

## Reference

See REFERENCE.md

## Limitations

## Development

## Release Notes/Contributors/Etc. **Optional**

