# Message Queue Tradeoffs — SQS, SNS, Kafka, Redis, RabbitMQ, Postgres

Six very different tools get reached for when someone says "put it on a queue". They are not
interchangeable: one is a log, one is a fan-out bus, one is an in-memory data structure, one is
a relational table pressed into service. Picking the wrong one shows up later as lost messages,
runaway ops cost, or a system that cannot replay when you need it to.

This note covers, for each one: **how it scales**, **how it handles failure and retry**, its
**best use case**, and three honest **pros/cons**.

An interactive version with a live simulation and side-by-side comparison tables lives in
[message-queue-tradeoffs.html](message-queue-tradeoffs.html).

---

## The one-line mental model

| System | What it actually is |
|---|---|
| **SQS** | A fully-managed, effectively-infinite distributed **queue**. Work in, work out, deleted on ack. |
| **SNS** | A managed **pub/sub fan-out bus**. One publish, N subscribers, no storage. |
| **Kafka** | A partitioned, replicated, **durable commit log**. Consumers track an offset; data is retained. |
| **Redis** | An **in-memory** data structure server; queues via Lists or Streams. Fast, small, volatile. |
| **RabbitMQ** | A classic **AMQP broker**: exchanges route to queues with rich rules, per-message ack. |
| **Postgres** | A **relational table as a queue** via `SELECT ... FOR UPDATE SKIP LOCKED`. Transactional. |

---

## SQS (Amazon Simple Queue Service)

**What it is.** A managed distributed queue. You never run a server. Standard queues are
at-least-once with best-effort ordering; FIFO queues give exactly-once processing and strict
ordering within a message group, capped near 300–3000 msg/s.

**Scale.** Standard queues scale horizontally and essentially without limit — AWS shards behind
the scenes, so you can push near-unbounded throughput with no capacity planning. FIFO trades that
for ordering and is rate-capped. Messages up to 256 KB (larger via S3 pointer / extended client).

**Failure & retry.** This is SQS's strong suit. A consumer receives a message, which becomes
*invisible* for the **visibility timeout**. If the consumer crashes or does not delete it in time,
the message reappears automatically for redelivery. After `maxReceiveCount` failed receives, a
**redrive policy** moves it to a **dead-letter queue** so poison messages cannot block the line.
No custom retry code required.

**Best use case.** Decoupling microservices and buffering background jobs on AWS where you want
zero ops and built-in retry + DLQ, and you do not need replay or ordering across everything.

- **Pros:** fully managed, zero ops; effectively infinite scale; visibility-timeout + DLQ retry is
  built in and battle-tested.
- **Cons:** AWS-only lock-in; no replay — once deleted a message is gone; standard queues can
  deliver duplicates and reorder, and FIFO throughput is limited.

---

## SNS (Amazon Simple Notification Service)

**What it is.** A managed pub/sub notification bus. A publisher sends one message to a **topic**;
SNS **fans it out** to every subscriber — SQS queues, Lambda, HTTP endpoints, email, SMS. It does
not store messages for later pull; it pushes and forgets.

**Scale.** Very high fan-out and throughput, managed. The canonical AWS pattern is
**SNS → many SQS** (fan-out): SNS multiplies the message, each SQS queue buffers durably for its
own consumer group. SNS alone has no backlog to consume from.

**Failure & retry.** SNS retries delivery per subscriber with a **delivery policy** (backoff
schedule). If an endpoint stays down past the retry budget, the message can be sent to an SNS
**DLQ** (an SQS queue). Because there is no stored log, an offline subscriber that has no DLQ and
exhausts retries simply misses the message — which is why durable fan-out pairs SNS with SQS.

**Best use case.** One event, many independent reactions — fan-out to several services at once,
push notifications, and event broadcasting on AWS.

- **Pros:** effortless one-to-many fan-out; many delivery protocols (SQS, Lambda, HTTP, email,
  SMS) out of the box; managed and scales for you.
- **Cons:** no storage or replay — a subscriber offline without a DLQ loses the message; per-message
  filtering is limited vs a real broker; AWS-only.

---

## Kafka (Apache Kafka)

**What it is.** A distributed, partitioned, replicated commit log. Producers append to **topics**
split into **partitions**; consumers in a **consumer group** each own partitions and advance an
**offset**. Messages are **retained** on disk (by time or size) whether or not they were consumed.

**Scale.** The throughput champion — millions of messages/sec. You scale by adding **partitions**
and **brokers**; partitions are the unit of parallelism. Ordering is guaranteed only *within* a
partition. Replication across brokers gives durability and availability.

**Failure & retry.** Different philosophy from a queue. There is no per-message ack/delete —
recovery is just **not committing the offset**, so on restart the consumer re-reads from the last
committed offset (**replay**). Retries are the application's job: retry topics, a
**dead-letter topic**, and idempotent/transactional producers for exactly-once *within Kafka*.
Because data is retained, you can rewind and reprocess history.

**Best use case.** High-throughput event streaming, event sourcing, log/metrics pipelines, and any
system where multiple independent consumers must read the same stream and you need **replay**.

- **Pros:** massive throughput and horizontal scale; durable retained log with full replay/rewind;
  many independent consumer groups read the same data at their own pace.
- **Cons:** heaviest to operate and reason about; ordering only within a partition; overkill and
  high-latency-to-set-up for simple point-to-point queues.

---

## Redis (Lists / Streams)

**What it is.** An in-memory data-structure server. Queues are built from **Lists**
(`LPUSH`/`BRPOP`, or reliable `LMOVE`/`BRPOPLPUSH`) or **Streams** (`XADD`/`XREADGROUP` with
consumer groups, offsets, and a pending-entries list). Everything lives in RAM.

**Scale.** Blazing low latency (sub-millisecond) and high throughput on a single node. Scaling
past one node means **Redis Cluster** sharding, which is more work than Kafka's partitions. Memory
is the ceiling — the whole dataset must fit in RAM, so it is a poor fit for huge backlogs.

**Failure & retry.** Weakest durability of the six. Persistence is **RDB snapshots** (lossy between
snapshots) or **AOF** (better, still a window). A crash can lose in-flight data. Lists have no
built-in retry; you hand-roll reliability with `RPOPLPUSH` into a processing list. **Streams** are
better: a consumer group tracks a **PEL** (pending entries list), and `XCLAIM`/`XAUTOCLAIM` let you
re-deliver messages a dead consumer never acked. Streams also support `MAXLEN` trimming (drops
oldest) so an unbounded backlog can silently lose data.

**Best use case.** Low-latency job queues and real-time work where a small window of loss on crash
is acceptable and you already run Redis — task queues (Celery, Sidekiq, BullMQ), rate work, ephemeral
event buffers.

- **Pros:** extremely fast, sub-ms latency; trivial to set up if Redis is already in your stack;
  Streams add consumer groups, offsets, and PEL-based redelivery.
- **Cons:** in-memory means limited backlog and real risk of data loss on crash; durability and
  clustering are weaker/more manual than Kafka or SQS; not built for long-term retention.

---

## RabbitMQ

**What it is.** The classic message broker, AMQP-based, written in Erlang. Producers publish to an
**exchange**; binding rules route to **queues**; consumers get messages and **ack/nack** each one.
Rich routing (direct, topic, headers, fanout), priorities, TTL, and dead-letter exchanges.

**Scale.** Great for moderate volumes with complex routing; lower ceiling than Kafka for raw
streaming. **Classic queues do not shard** — a queue lives on one node. **Quorum queues** (Raft)
add replicated durability; **Streams** (3.9+) add Kafka-like retained, replayable logs and close
the throughput gap.

**Failure & retry.** Per-message **ack** is the core mechanism: unacked messages on a dropped
connection are **requeued** automatically. A **nack/reject** can requeue or route to a
**dead-letter exchange (DLX)**; combined with **TTL** you get delayed retries and backoff. This
per-message control and routing is RabbitMQ's biggest strength over Kafka's offset model.

**Best use case.** Complex routing and reliable task distribution — RPC/request-reply, priority
work, per-message TTL and delayed retries, and workflows where different messages must go to
different consumers by rule.

- **Pros:** flexible, powerful routing (topic/header/priority); precise per-message ack + DLX +
  TTL retry control; mature, protocol-rich (AMQP, MQTT, STOMP).
- **Cons:** classic queues do not scale horizontally (single-node per queue); lower throughput than
  Kafka for big streams; replay needs Streams — classic queues delete on ack.

---

## Postgres (table as a queue)

**What it is.** A relational database used as a durable queue. A `jobs` table holds rows; workers
pull with `SELECT ... FOR UPDATE SKIP LOCKED LIMIT n` so concurrent workers grab disjoint rows
without blocking each other, process them, and update/delete in the same transaction.

**Scale.** Lowest ceiling of the six — bounded by one database's write throughput and connection
pool, and `VACUUM` pressure from high-churn insert/delete. Fine for thousands of jobs/min, not
millions/sec. `LISTEN/NOTIFY` avoids busy-polling for new work.

**Failure & retry.** Its killer feature is **transactional consistency**: enqueue the job in the
**same transaction** as your business write, so there is no dual-write problem and no lost or
phantom messages (the transactional-outbox pattern). Retry is a plain `attempts` column and a
`next_run_at` timestamp you increment on failure; a status column plus a threshold gives you a
DLQ-equivalent. All of it is just SQL you already understand.

**Best use case.** You already run Postgres, volume is modest, and you want the job enqueue to be
**atomic with your data changes** — outbox pattern, low-to-medium background jobs, exactly-once
side effects without adding new infrastructure.

- **Pros:** transactional — enqueue atomically with your business data (no dual-write / outbox);
  zero new infrastructure and full SQL visibility/debuggability; durable and consistent by default.
- **Cons:** low throughput ceiling; high-churn queues cause table bloat and `VACUUM` load;
  you hand-build retry, DLQ, visibility, and scheduling that SQS/Rabbit give for free.

---

## Comparison at a glance

| Property | SQS | SNS | Kafka | Redis | RabbitMQ | Postgres |
|---|---|---|---|---|---|---|
| **Model** | Queue | Pub/sub fan-out | Commit log | In-mem list/stream | AMQP broker | Table as queue |
| **Delivery** | At-least-once (FIFO: exactly-once) | At-least-once | At-least-once (exactly-once in-Kafka) | At-least-once (Streams) | At-least-once | Exactly-once (txn) |
| **Ordering** | Best-effort (FIFO: per group) | None | Per partition | Per stream | Per queue | By query |
| **Throughput** | Very high | Very high | Extreme | High (1 node) | Moderate–high | Low–moderate |
| **Latency** | ~10–100 ms | ~10–100 ms | Low (1–25 ms) | Sub-ms | Low (~1 ms) | ms–10s ms |
| **Durability** | Managed, high | None (transient) | Disk + replication | RAM (lossy persist) | Disk (quorum) | Full ACID |
| **Replay** | No | No | Yes (retained log) | Streams: limited | Streams only | Yes (rows persist) |
| **Retry** | Visibility timeout | Delivery policy | Offset / retry topic | XCLAIM / manual | ack/nack + DLX | attempts column |
| **DLQ** | Built-in | Built-in (to SQS) | DL topic (manual) | Manual | DLX | Status column |
| **Scale model** | Auto (managed) | Auto (managed) | Partitions + brokers | Cluster sharding | Nodes (no shard) | Vertical / one DB |
| **Ops overhead** | None | None | High | Low–medium | Medium | Low (already run it) |
| **Managed** | Yes (AWS) | Yes (AWS) | MSK / Confluent | ElastiCache / self | CloudAMQP / self | RDS / self |

---

## How to choose

- **On AWS, decouple services with built-in retry, no ops** → **SQS**. Add a DLQ and move on.
- **One event, many independent reactions on AWS** → **SNS** (usually **SNS → SQS** for durable fan-out).
- **High-throughput streaming, event sourcing, replay, many consumer groups** → **Kafka**.
- **Sub-ms job queue, Redis already in the stack, small window of loss OK** → **Redis** (prefer Streams).
- **Complex routing, priorities, per-message TTL/retry, RPC** → **RabbitMQ**.
- **Enqueue must be atomic with a DB write, modest volume, no new infra** → **Postgres** (outbox).

The default mistake is reaching for Kafka when a queue would do, or building a queue in Postgres
that outgrows the database. Match the tool to whether you need **fan-out**, **replay**,
**routing**, **transactional enqueue**, or just **decoupling with retry** — and let scale, failure
handling, and ops budget break the tie.
