# heartbeat


#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with heartbeat](#setup)
    * [What heartbeat affects](#what-heartbeat-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with heartbeat](#beginning-with-heartbeat)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Description

This module installs and configures the [heartbeat shipper](https://www.elastic.co/guide/en/beats/heartbeat/current/heartbeat-overview.html) by Elastic. It has been tested on Puppet 5.x and on the following OSes: Debian 9.1, CentOS 7.3, Ubuntu 16.04

## Setup

### What heartbeat affects

`heartbeat` configures the package repository to fetch the software, it installs it, it configures both the application (`/etc/heartbeat/heartbeat.yml`) and the service (`systemd` by default, but it is possible to manually switch to `init`) and it takes care that it is running and enabled.

### Setup Requirements

`heartbeat` needs `puppetlabs/stdlib`, `puppetlabs/apt` (for Debian and derivatives), `puppet/yum` (for RedHat or RedHat-like systems), `darin-zypprepo` (on SuSE based system)

### Beginning with heartbeat

The module can be installed manually, typing `puppet module install noris-heartbeat`, or by means of an environment manager (r10k, librarian-puppet, ...).

`heartbeat` requires at least the `outputs` and `monitors` sections in order to start. Please refer to the software documentation to find out the [available monitors] (https://www.elastic.co/guide/en/beats/heartbeat/current/configuration-heartbeat-options.html) and the [supported outputs] (https://www.elastic.co/guide/en/beats/heartbeat/current/configuring-output.html). On the other hand, the sections [logging] (https://www.elastic.co/guide/en/beats/heartbeat/current/configuration-logging.html) and [queue] (https://www.elastic.co/guide/en/beats/heartbeat/current/configuring-internal-queue.html) already contains meaningful default values.

A basic setup checking a host by ping/icmp every 5 minutes and writing the results directly in Elasticsearch:

```puppet
class{'heartbeat':
    monitors => [
      {
        'type' => 'icmp',
        'schedule' => '*/5 * * * * * *',
        'hosts' => ['myhost', 'myotherhost'],
      },
    ],
    outputs => {
      'elasticsearch' => {
        'hosts' => ['http://localhost:9200'],
        'index' => 'heartbeat-%{+YYYY.MM.dd}',
      },
    },
```

The same example using Hiera:

```
classes:
  include:
    - 'heartbeat'

heartbeat::monitors:
  - type: 'icmp'
    schedule: '*/5 * * * * * *'
    hosts:
      - 'myhost'
      - 'myotherhost'

heartbeat::outputs:
  elasticsearch:
    hosts:
      - 'http://localhost:9200'
    index: "heartbeat-%%{}{+YYYY.MM.dd}"
```

## Usage

The configuration is written to the configuration file `/etc/heartbeat/heartbeat.yml` in yaml format. The default values follow the upstream (as of the time of writing).

Send data to two Redis servers, loadbalancing between the instances.

```puppet
class{'heartbeat':
    monitors => [
      {
        'type' => 'icmp',
        'schedule' => '*/5 * * * * * *',
        'hosts' => ['myhost', 'myotherhost'],
      },
    ],
    outputs => {
      'redis' => {
        'hosts' => ['localhost:6379', 'other_redis:6379'],
        'key' => 'heartbeat',
      },
    },
```
or, using Hiera

```
classes:
  include:
    - 'heartbeat'

heartbeat::monitors:
  - type: 'icmp'
    schedule: '*/5 * * * * * *'
    hosts:
      - 'myhost'
      - 'myotherhost'

heartbeat::outputs:
  elasticsearch:
    hosts:
      - 'localhost:6379'
      - 'itger:redis:6379'
    index: 'heartbeat'
```


## Reference

* [Public Classes](#public-classes)
	* [Class: heartbeat](#class-heartbeat)
* [Private Classes](#private-classes)
	* [Class: heartbeat::repo](#class-heartbeat-repo)
	* [Class: heartbeat::install](#class-heartbeat-install)
	* [Class: heartbeat::config](#class-heartbeat-config)
	* [Class: heartbeat::service](#class-heartbeat-service)


### Public Classes

#### Class: `heartbeat`

Installation and configuration.

**Parameters**:

* `beat_name`: [String] the name of the shipper (default: the *hostname*).
* `fields_under_root`: [Boolean] whether to add the custom fields to the root of the document (default is *false*).
* `queue`: [Hash] heartbeat's internal queue, before the events publication (default is *4096* events in *memory* with immediate flush).
* `logging`: [Hash] the heartbeat's logfile configuration (default: writes to `/var/log/heartbeat/heartbeat`, maximum 7 files, rotated when bigger than 10 MB).
* `outputs`: [Hash] the options of the mandatory [outputs] (https://www.elastic.co/guide/en/beats/heartbeat/current/configuring-output.html) section of the configuration file (default: undef).
* `major_version`: [Enum] the major version of the package to install (default: '6', the only accepted value. Implemented for future reference).
* `ensure`: [Enum 'present', 'absent']: whether Puppet should manage `heartbeat` or not (default: 'present').
* `service_provider`: [Enum 'systemd', 'init'] which boot framework to use to install and manage the service (default: 'systemd').
* `service_ensure`: [Enum 'enabled', 'running', 'disabled', 'unmanaged'] the status of the heartbeat service (default 'enabled'). In more details:
	* *enabled*: service is running and started at every boot;
	* *running*: service is running but not started at boot time;
	* *disabled*: service is not running and not started at boot time;
	* *unamanged*: Puppet does not manage the service.
* `package_ensure`: [String] the package version to install. It could be 'latest' (for the newest release) or a specific version number, in the format *x.y.z*, i.e., *6.6.1* (default: latest).
* `config_file_mode`: [String] the octal file mode of the configuration file `/etc/heartbeat/heartbeat.yml` (default: 0644).
* `disable_configtest`: [Boolean] whether to check if the configuration file is valid before attempting to run the service (default: true).
* `tags`: [Array[Strings]]: the tags to add to each document (default: undef).
* `fields`: [Hash] the fields to add to each document (default: undef).
* `xpack`: [Hash] the configuration to export internal metrics to an Elasticsearch monitoring instance  (default: undef).
* `monitors`: [Array[Hash]] the required [monitors] (https://www.elastic.co/guide/en/beats/heartbeat/current/configuration-heartbeat-options.html) to load (default: undef).
* `processors`: [Array[Hash]] the optional [processors] (https://www.elastic.co/guide/en/beats/heartbeat/current/defining-processors.html) for event enhancement (default: undef).

### Private Classes

#### Class: `heartbeat::repo`
Configuration of the package repository to fetch heartbeat.

#### Class: `heartbeat::install`
Installation of the heartbeat package.

#### Class: `heartbeat::config`
Configuration of the heartbeat daemon.

#### Class: `heartbeat::service`
Management of the heartbeat service.


## Limitations

This module does not load the index template in Elasticsearch nor the heartbeat example dashboards in Kibana. These two tasks should be carried out manually. Please follow the documentation to [manually load the index template in Elasticsearch] (https://www.elastic.co/guide/en/beats/heartbeat/current/heartbeat-template.html#load-template-manually-alternate) and to [import the heartbeat dashboards in Kibana] (https://www.elastic.co/guide/en/beats/devguide/current/import-dashboards.html).

The option `manage_repo` does not work properly on SLES. This means that, even if set to *false*, the repo file 
`/etc/zypp/repos.d/beats.repo` will be created and the corresponding repo will be enabled.

## Development

Please feel free to report bugs and to open pull requests for new features or to fix a problem.
