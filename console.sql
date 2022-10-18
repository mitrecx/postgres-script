--###############################  定义表   ###############################
create table users
(
    id   int,
    name varchar(20)
);

insert into users(id, name)
values (2, 'mitre');

select *
from users;

---------------------------------
-------------------6 parallel query-----------
create table test_big1
(
    id          int4,
    name        character varying(32),
    create_time timestamp without time zone default clock_timestamp()
);

-- insert 50_000_000
insert into  test_big1(id, name)
select n, n||'_test' from generate_series(1,50000000) n;

select * from test_big1 where name = '1_test';


set max_parallel_workers_per_gather=0;
explain analyze select * from test_big1 where name = '1_test';
-- Seq Scan on test_big1  (cost=0.00..991738.10 rows=1 width=25) (actual time=1.200..24827.419 rows=1 loops=1)
--   Filter: ((name)::text = '1_test'::text)
--   Rows Removed by Filter: 49999999
-- Planning Time: 0.052 ms
-- Execution Time: 24827.442 ms

set max_parallel_workers_per_gather=2;
explain analyze select * from test_big1 where name = '1_test';
-- Gather  (cost=1000.00..628111.64 rows=1 width=25) (actual time=4.097..24571.208 rows=1 loops=1)
--   Workers Planned: 2
--   Workers Launched: 2
--   ->  Parallel Seq Scan on test_big1  (cost=0.00..627111.54 rows=1 width=25) (actual time=16364.815..24551.704 rows=0 loops=3)
--         Filter: ((name)::text = '1_test'::text)
--         Rows Removed by Filter: 16666666
-- Planning Time: 0.094 ms
-- Execution Time: 24571.245 ms

create index idx_test_big1_id on test_big1 using btree(id);

explain analyze select count(name) from  test_big1 where id < 10000000;
-- Aggregate  (cost=385788.36..385788.38 rows=1 width=8) (actual time=7306.805..7306.809 rows=1 loops=1)
--   ->  Index Scan using idx_test_big1_id on test_big1  (cost=0.56..360607.64 rows=10072290 width=13) (actual time=4.622..6533.601 rows=9999999 loops=1)
--         Index Cond: (id < 10000000)
-- Planning Time: 0.361 ms
-- Execution Time: 7306.872 ms

set max_parallel_workers_per_gather=2;
explain analyze select count(name) from  test_big1 where id < 10000000;
-- Finalize Aggregate  (cost=313344.80..313344.81 rows=1 width=8) (actual time=7341.427..7345.982 rows=1 loops=1)
--   ->  Gather  (cost=313344.58..313344.79 rows=2 width=8) (actual time=7341.415..7345.973 rows=3 loops=1)
--         Workers Planned: 2
--         Workers Launched: 2
--         ->  Partial Aggregate  (cost=312344.58..312344.59 rows=1 width=8) (actual time=7318.600..7318.602 rows=1 loops=3)
--               ->  Parallel Index Scan using idx_test_big1_id on test_big1  (cost=0.56..301852.61 rows=4196788 width=13) (actual time=1.653..7047.471 rows=3333333 loops=3)
--                     Index Cond: (id < 10000000)
-- Planning Time: 1.672 ms
-- Execution Time: 7346.033 ms

select version();
show server_version;
set max_parallel_workers_per_gather=0;
explain analyze select count(*) from  test_big1 where id < 10000000;
-- Aggregate  (cost=311926.36..311926.38 rows=1 width=8) (actual time=1750.536..1750.538 rows=1 loops=1)
--   ->  Index Only Scan using idx_test_big1_id on test_big1  (cost=0.56..286745.64 rows=10072290 width=0) (actual time=0.072..1189.193 rows=9999999 loops=1)
--         Index Cond: (id < 10000000)
--         Heap Fetches: 0
-- Planning Time: 0.082 ms
-- Execution Time: 1750.571 ms
explain select count(*) from  test_big1 where id < 10000000;

set max_parallel_workers_per_gather=2;
explain analyze select count(*) from  test_big1 where id < 10000000;
-- Finalize Aggregate  (cost=239482.80..239482.81 rows=1 width=8) (actual time=1223.099..1226.047 rows=1 loops=1)
--   ->  Gather  (cost=239482.58..239482.80 rows=2 width=8) (actual time=1223.088..1226.039 rows=3 loops=1)
--         Workers Planned: 2
--         Workers Launched: 2
--         ->  Partial Aggregate  (cost=238482.58..238482.60 rows=1 width=8) (actual time=1202.956..1202.957 rows=1 loops=3)
--               ->  Parallel Index Only Scan using idx_test_big1_id on test_big1  (cost=0.56..227990.61 rows=4196788 width=0) (actual time=1.404..972.290 rows=3333333 loops=3)
--                     Index Cond: (id < 10000000)
--                     Heap Fetches: 0
-- Planning Time: 0.093 ms
-- Execution Time: 1226.086 ms
