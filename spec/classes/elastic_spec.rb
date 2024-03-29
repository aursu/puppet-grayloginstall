# frozen_string_literal: true

require 'spec_helper'

local_facts = {
  'networking' => {
    'domain' => 'corpdldomain.tld',
    'fqdn' => 'logger.corpdldomain.tld',
    'hostname' => 'logger',
    'interfaces' => {
      'bond0' => {
        'mac' => 'f2:df:d3:61:5d:e9',
        'mtu' => 1500,
      },
      'dummy0' => {
        'mac' => 'ba:aa:05:75:69:34',
        'mtu' => 1500,
      },
      'eth0' => {
        'bindings' => [
          {
            'address' => '104.134.88.225',
            'netmask' => '255.255.255.0',
            'network' => '104.134.88.0',
          },
        ],
        'bindings6' => [
          {
            'address' => 'fe80::c252:fce7:8638:1604',
            'netmask' => 'ffff:ffff:ffff:ffff::',
            'network' => 'fe80::',
          },
        ],
        'ip' => '104.134.88.225',
        'ip6' => 'fe80::c252:fce7:8638:1604',
        'mac' => '00:50:56:b9:fe:f3',
        'mtu' => 1500,
        'netmask' => '255.255.255.0',
        'netmask6' => 'ffff:ffff:ffff:ffff::',
        'network' => '104.134.88.0',
        'network6' => 'fe80::',
      },
      'eth1' => {
        'bindings' => [
          {
            'address' => '192.168.200.225',
            'netmask' => '255.255.255.0',
            'network' => '192.168.200.0',
          },
        ],
        'bindings6' => [
          {
            'address' => 'fe80::fe97:cbdf:da6a:f003',
            'netmask' => 'ffff:ffff:ffff:ffff::',
            'network' => 'fe80::',
          },
        ],
        'ip' => '192.168.200.225',
        'ip6' => 'fe80::fe97:cbdf:da6a:f003',
        'mac' => '00:50:56:b9:80:76',
        'mtu' => 1500,
        'netmask' => '255.255.255.0',
        'netmask6' => 'ffff:ffff:ffff:ffff::',
        'network' => '192.168.200.0',
        'network6' => 'fe80::',
      },
      'lo' => {
        'bindings' => [
          {
            'address' => '127.0.0.1',
            'netmask' => '255.0.0.0',
            'network' => '127.0.0.0',
          },
        ],
        'bindings6' => [
          {
            'address' => '::1',
            'netmask' => 'ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff',
            'network' => '::1',
          },
        ],
        'ip' => '127.0.0.1',
        'ip6' => '::1',
        'mtu' => 65536,
        'netmask' => '255.0.0.0',
        'netmask6' => 'ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff',
        'network' => '127.0.0.0',
        'network6' => '::1',
      },
    },
    'ip' => '104.134.88.225',
    'ip6' => 'fe80::c252:fce7:8638:1604',
    'mac' => '00:50:56:b9:fe:f3',
    'mtu' => 1500,
    'netmask' => '255.255.255.0',
    'netmask6' => 'ffff:ffff:ffff:ffff::',
    'network' => '104.134.88.0',
    'network6' => 'fe80::',
    'primary' => 'eth0',
  },
}

describe 'grayloginstall::elastic' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) do
        os_facts.merge(local_facts)
      end

      it { is_expected.to compile }

      it {
        is_expected.to contain_class('elasticsearch')
          .with_config(
            'cluster.name'                       => 'graylog',
            'action.auto_create_index'           => '.watches,.triggered_watches,.watcher-history-*',
            'network.host'                       => '_site_',
            'discovery.zen.ping.unicast.hosts'   => ['127.0.0.1', '[::1]'],
            'discovery.zen.minimum_master_nodes' => 2,
          )
      }

      context 'with discovery seed hosts' do
        let(:params) do
          {
            'discovery_seed_hosts' => [
              '192.168.200.225', '192.168.200.226', 'fe80::250:56ff:fea5:ef71'
            ],
          }
        end

        it {
          is_expected.to contain_class('elasticsearch')
            .with_config(
              'cluster.name'                       => 'graylog',
              'action.auto_create_index'           => '.watches,.triggered_watches,.watcher-history-*',
              'network.host'                       => '_site_',
              'discovery.zen.ping.unicast.hosts'   => ['192.168.200.226', '[fe80::250:56ff:fea5:ef71]'],
              'discovery.zen.minimum_master_nodes' => 2,
            )
        }
      end

      context 'with enabled fallback to default ip' do
        let(:pre_condition) do
          <<-PRECOND
          class { 'grayloginstall::cluster':
            fallback_default => true,
          }
          PRECOND
        end
        let(:params) do
          {
            'discovery_seed_hosts' => [
              '192.168.200.225', '192.168.200.226', 'fe80::250:56ff:fea5:ef71'
            ],
          }
        end

        it {
          is_expected.to contain_class('elasticsearch')
            .with_config(
              'cluster.name'                       => 'graylog',
              'action.auto_create_index'           => '.watches,.triggered_watches,.watcher-history-*',
              'network.host'                       => '104.134.88.225',
              'discovery.zen.ping.unicast.hosts'   => ['192.168.200.226', '[fe80::250:56ff:fea5:ef71]'],
              'discovery.zen.minimum_master_nodes' => 2,
            )
        }
      end
    end
  end
end
