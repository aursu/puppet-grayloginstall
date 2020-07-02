# Graylog

1. [Index model](https://docs.graylog.org/en/latest/pages/configuration/index_model.html#index-model)

    - index rotation

    - data retention

2. [Backup](https://docs.graylog.org/en/3.3/pages/configuration/backup.html)

    - Elasticsearch and MongoDB are databases, for both you should implement the ability to make a data dump and restore that -
    if you want to be able to restore the current state.

3. [Permission system](https://docs.graylog.org/en/3.3/pages/users_and_roles/permission_system.html#permissions)

## Elasticsearch

1. [Types and Mappings](https://www.elastic.co/guide/en/elasticsearch/guide/2.x/mapping.html#mapping)

2. [Configuring Analyzers](https://www.elastic.co/guide/en/elasticsearch/guide/2.x/configuring-analyzers.html#configuring-analyzers)

3. [Index Settings (replicatio setings)](https://www.elastic.co/guide/en/elasticsearch/guide/2.x/_index_settings.html#_index_settings)

4. [Index Aliases and Zero Downtime](https://www.elastic.co/guide/en/elasticsearch/guide/2.x/index-aliases.html#index-aliases)

5. [Force Merge (index optimization)](https://www.elastic.co/guide/en/elasticsearch/reference/2.4/indices-forcemerge.html)

6. [Segment Merging](https://www.elastic.co/guide/en/elasticsearch/guide/2.x/merge-process.html#merge-process)

7. [Open/Close Index API](https://www.elastic.co/guide/en/elasticsearch/reference/2.4/indices-open-close.html)

8. [Snapshot and restore](https://www.elastic.co/guide/en/elasticsearch/reference/current/snapshot-restore.html)

## MongoDB

1. [MongoDB Backup Methods](https://docs.mongodb.com/manual/core/backups/#back-up-by-copying-underlying-data-files)

