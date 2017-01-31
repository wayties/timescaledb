
-- Sets a database and hostname as a meta node.
CREATE OR REPLACE FUNCTION set_meta(
    database_name NAME,
    hostname      TEXT
)
    RETURNS VOID LANGUAGE PLPGSQL VOLATILE AS
$BODY$
DECLARE
    meta_row _iobeamdb_catalog.meta;
BEGIN
    SELECT *
    INTO meta_row
    FROM _iobeamdb_catalog.meta
    LIMIT 1;

    IF meta_row IS NULL THEN
        INSERT INTO _iobeamdb_catalog.meta (database_name, hostname, server_name)
        VALUES (database_name, hostname, database_name);
    ELSE
        IF meta_row.database_name <> database_name OR meta_row.hostname <> hostname THEN
            RAISE EXCEPTION 'Changing meta info is not supported'
            USING ERRCODE = 'IO101';
        END IF;
    END IF;
END
$BODY$;

-- Adds a new node to the cluster, with its database name and hostname.
CREATE OR REPLACE FUNCTION add_node(
    database_name NAME,
    hostname      TEXT
)
    RETURNS VOID LANGUAGE PLPGSQL VOLATILE AS
$BODY$
DECLARE
    schema_name NAME;
BEGIN
    schema_name := format('remote_%s', database_name);
    IF database_name = current_database() THEN
        schema_name = '_iobeamdb_catalog';
    END IF;

    BEGIN
    INSERT INTO _iobeamdb_catalog.node (database_name, schema_name, server_name, hostname)
    VALUES (database_name, schema_name, database_name, hostname);
    EXCEPTION
        WHEN SQLSTATE '42710' THEN
            RAISE EXCEPTION 'Node % already exists', database_name
            USING ERRCODE = 'IO120';
    END;

END
$BODY$;

-- Adds new user credentials for the cluster.
CREATE OR REPLACE FUNCTION add_cluster_user(
    username TEXT,
    password TEXT
)
    RETURNS VOID LANGUAGE PLPGSQL VOLATILE AS
$BODY$
DECLARE
BEGIN
    INSERT INTO _iobeamdb_catalog.cluster_user (username, password)
    VALUES (username, password);
EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'User % already exists', username
            USING ERRCODE = 'IO130';
END
$BODY$;

CREATE OR REPLACE FUNCTION add_partition_epoch(
    hypertable_id               INTEGER,
    keyspace_start              SMALLINT [],
    partitioning_column         NAME,
    partitioning_func_schema    NAME,
    partitioning_func           NAME,
    tablespace_name             NAME
)
    RETURNS VOID LANGUAGE SQL VOLATILE AS
$BODY$
    WITH epoch AS (
        INSERT INTO _iobeamdb_catalog.partition_epoch (hypertable_id, start_time, end_time, partitioning_func_schema, 
            partitioning_func, partitioning_mod, partitioning_column)
        VALUES (hypertable_id, NULL, NULL, partitioning_func_schema, partitioning_func, 32768, partitioning_column)
        RETURNING id
    )
    INSERT INTO _iobeamdb_catalog.partition (epoch_id, keyspace_start, keyspace_end, tablespace)
    SELECT
        epoch.id,
        lag(start, 1, 0)
        OVER (),
        start - 1,
        tablespace_name
    FROM unnest(keyspace_start :: INT [] || (32768) :: INT) start, epoch
$BODY$;

CREATE OR REPLACE FUNCTION add_equi_partition_epoch(
    hypertable_id               INTEGER,
    number_partitions           SMALLINT,
    partitioning_column         NAME,
    partitioning_func_schema    NAME,
    partitioning_func           NAME,
    tablespace_name             NAME
)
    RETURNS VOID LANGUAGE SQL VOLATILE AS
$BODY$
SELECT add_partition_epoch(
    hypertable_id,
    (SELECT ARRAY(SELECT start * 32768 / (number_partitions)
                  FROM generate_series(1, number_partitions - 1) AS start) :: SMALLINT []),
    partitioning_column,
    partitioning_func_schema,
    partitioning_func,
    tablespace_name
)
$BODY$;