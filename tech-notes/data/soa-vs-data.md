# SOA vs Data

Should I fix a problem with Services or using Data Engineering?

## Data problem characteristics

- Looking back in time (historical perspective)
- Cross-domain analysis (need to see across multiple systems)
- Exploratory (don't know exact questions upfront)
- Answers "what happened" or "what will happen"
- Data completeness and accuracy over time matter most
- Multiple consumers with different questions
- Read-heavy workloads
- Some: Aggregations, trends, patterns (not all)
- Eventually consistent is acceptable
- Batch processing is acceptable

## SOA problem characteristics

- Transactional (state changes)
- Real-time operational needs
- Single domain or bounded context
- Write-heavy or balanced read/write
- Business logic execution matters
- Known, specific operations
- Answers "what is right now" or "make this happen"
- Usualy Request/response model
- Should have clear service ownership and boundaries

## In Synthesis

The core difference: Data problems are about understanding what already happened across many contexts. SOA problems are about making things happen right now within clear boundaries.

Besides analytical, reporting, predictions, IMHO Data is the "Join" that could be expensive with many Services.