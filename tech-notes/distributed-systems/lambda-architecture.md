# Lambda Architecture

## What is it?

Lambda Architecture is a data processing architecture designed to handle massive quantities of data by combining batch and real-time stream processing methods. It provides a unified approach to building data systems that can process both historical and real-time data, delivering comprehensive and accurate views of data.

The architecture consists of three layers:
- **Batch Layer**: Stores the master dataset (immutable, append-only raw data) and pre-computes batch views
- **Speed Layer**: Processes real-time data to provide low-latency views, compensating for the batch layer's high latency
- **Serving Layer**: Indexes batch views for ad-hoc queries and merges results from both batch and speed layers

## Who created it? When?

Lambda Architecture was created by **Nathan Marz** around **2011**. He developed this architecture while working at Twitter to solve the challenges of processing large-scale data. Nathan Marz later detailed the architecture in his book "Big Data: Principles and Best Practices of Scalable Real-Time Data Systems" published in 2015.

## How it works?

1. **Data Ingestion**: All incoming data flows into both the batch layer and speed layer simultaneously

2. **Batch Layer Processing**:
   - Stores all raw data in an immutable, append-only master dataset
   - Periodically runs MapReduce or similar batch jobs (e.g., every few hours)
   - Produces batch views that are complete but have high latency

3. **Speed Layer Processing**:
   - Processes only recent data in real-time using stream processing
   - Creates real-time views that are fast but potentially incomplete
   - Data in speed layer is temporary and gets replaced when batch layer catches up

4. **Serving Layer**:
   - Loads and indexes batch views for efficient querying
   - Merges batch views with real-time views from speed layer
   - Returns combined results to queries

5. **Query Resolution**:
   ```
   Query Result = Batch View + Real-time View
   ```

## Pros

- **Fault Tolerance**: Immutable master dataset allows recomputation if errors occur
- **Low Latency**: Speed layer provides real-time results while batch processes
- **Scalability**: Both layers can scale independently
- **Accuracy**: Batch layer ensures eventually consistent and accurate results
- **Flexibility**: Can handle both historical analysis and real-time queries
- **Data Recovery**: Raw data is preserved, enabling reprocessing with new algorithms

## Cons

- **Complexity**: Maintaining two separate codebases (batch and streaming) is complex
- **Code Duplication**: Same logic often needs to be implemented twice in different frameworks
- **Operational Overhead**: Running and monitoring two processing systems increases operational burden
- **Synchronization Challenges**: Merging batch and real-time views can be tricky
- **Resource Intensive**: Requires more infrastructure to run parallel systems
- **Debugging Difficulty**: Issues can be hard to trace across two different pipelines

## Use Cases

- **Social Media Analytics**: Processing tweets, posts, and user interactions at scale (Twitter, Facebook)
- **Real-time Dashboards**: Business intelligence systems requiring both historical trends and live metrics
- **Fraud Detection**: Combining historical pattern analysis with real-time transaction monitoring
- **IoT Data Processing**: Handling sensor data streams while maintaining historical records
- **E-commerce Recommendations**: Real-time personalization backed by batch-computed models
- **Log Analytics**: Processing application logs for both real-time monitoring and historical analysis
- **Ad Tech**: Real-time bidding systems with historical campaign performance analysis
- **Financial Services**: Risk analysis combining historical data with live market feeds
