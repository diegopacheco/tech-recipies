# Token hard vs Token smart

## Token harder
Use more agents, more parallel sessions, more context, and more inference tokens to maximize output:
* Run several coding agents simultaneously.
* Keep agents working continuously.
* Use the most powerful models.
* Generate many implementations and select the best.
* Try to consume the full subscription or compute budget.
The underlying belief is:
The main constraint is our inability to deploy enough AI computation.
This can increase throughput, but it may also produce more code than humans can understand, review, or safely integrate. More tokens can mean more output—not necessarily better decisions.

## Token smarter
Design the workflow so that every expensive model interaction has greater leverage:
* Give the model cleaner and more relevant context.
* Separate research, design, planning, implementation, and verification.
* Restart sessions when the trajectory becomes poisoned.
* Compact useful knowledge into durable documents.
* Spend human attention on architecture and consequential decisions.
* Use cheaper models only for well-defined, lower-risk steps.
The underlying belief is:
The real constraint is not token availability; it is our ability to direct tokens toward the right problem.
A simple comparison:
Token harder	Token smarter
Increase AI activity	Increase the value of AI activity
More agents and runs	Better context and decomposition
Optimize throughput	Optimize decisions and outcomes
Risk generating more slop	Risk moving more slowly initially
Easier to start	Harder to design well
The mature approach is usually a combination: token smarter first, then token harder where the workflow is measurable and safe.

