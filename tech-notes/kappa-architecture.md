# Kappa Architecture

## What is it?

Kappa Architecture is a data processing architecture that simplifies the Lambda Architecture by removing the batch layer entirely. It uses a single stream processing engine to handle all data processing needs, treating everything as a stream of events. The architecture relies on a distributed log (like Apache Kafka) as the source of truth and reprocesses data by replaying the log when needed.

The architecture consists of two main components:
- **Stream Processing Layer**: Handles all data processing in real-time using a single codebase
- **Serving Layer**: Stores and serves the processed results for queries

## Who created it? When?

Kappa Architecture was proposed by **Jay Kreps** in **2014**. He introduced the concept in his blog post "Questioning the Lambda Architecture" while working at LinkedIn. Jay Kreps is also one of the co-creators of Apache Kafka, which is a key enabling technology for this architecture.

## How it works?

1. **Data Ingestion**: All events are appended to an immutable, distributed log (e.g., Kafka)

2. **Stream Processing**:
   - A single stream processing engine reads from the log
   - Processes events in real-time and produces derived views
   - Same code handles both real-time and historical data

3. **Reprocessing Strategy**:
   - When logic changes or reprocessing is needed, start a new processing job
   - New job reads from the beginning of the log (or a specific offset)
   - Produces output to a new table/view
   - Once caught up, switch queries to the new view and discard the old one

4. **Serving Layer**:
   - Stores processed results in databases optimized for queries
   - Serves results to applications and users

5. **Log Retention**:
   - The log retains data for a configurable period (or indefinitely with compaction)
   - Enables full reprocessing when algorithms change

## Pros

- **Simplicity**: Single codebase for all processing eliminates code duplication
- **Easier Maintenance**: One system to debug, monitor, and maintain
- **Consistency**: Same processing logic for real-time and reprocessing
- **Lower Operational Costs**: Fewer systems to operate and manage
- **Faster Development**: Changes only need to be made in one place
- **Unified Processing Model**: Stream processing handles everything
- **Easier Testing**: Single code path simplifies testing and validation

## Cons

- **Reprocessing Time**: Replaying large logs can be slow without batch optimization
- **Log Storage Costs**: Keeping long-term logs requires significant storage
- **Framework Maturity**: Stream processing frameworks historically less mature than batch
- **Windowing Complexity**: Complex windowed aggregations can be challenging
- **Not Ideal for All Workloads**: Some batch-oriented computations may be less efficient
- **Log Retention Limits**: Cannot reprocess beyond log retention period
- **Resource Spikes**: Reprocessing while handling live traffic can strain resources

## Use Cases

- **Event Sourcing Systems**: Applications where state is derived from event streams
- **Real-time Analytics**: Dashboards and metrics that need continuous updates
- **Microservices Event Streaming**: Event-driven architectures using Kafka
- **Change Data Capture (CDC)**: Replicating database changes across systems
- **User Activity Tracking**: Processing clickstreams and user behavior data
- **Financial Transactions**: Payment processing and account balance tracking
- **Log Processing**: Centralized log aggregation and analysis
- **IoT Event Processing**: Handling sensor data with simpler processing requirements
- **Recommendation Engines**: Real-time personalization based on recent behavior
- **Audit Trails**: Systems requiring complete history and replayability
