DROP FUNCTION IF EXISTS _timescaledb_internal.get_version();
DROP FUNCTION IF EXISTS drop_chunks(INTERVAL, NAME, NAME, BOOLEAN);
DROP FUNCTION IF EXISTS drop_chunks(ANYELEMENT, NAME, NAME, BOOLEAN);
DROP FUNCTION IF EXISTS _timescaledb_internal.drop_chunks_impl(BIGINT, NAME, NAME, BOOLEAN, BOOLEAN);
DROP FUNCTION IF EXISTS _timescaledb_internal.drop_chunks_type_check(REGTYPE, NAME, NAME);
DROP FUNCTION IF EXISTS _timescaledb_internal.dimension_get_time(INTEGER);
DROP FUNCTION IF EXISTS create_hypertable(regclass, name, name, integer, name, name, anyelement, boolean, boolean, regproc, boolean, text, regproc);
