# Dolt

## 1. What is Dolt?

Dolt is a SQL database with Git-style version control built in. It is the world's first version-controlled SQL database — think Git and MySQL had a baby. You can fork, clone, branch, merge, push, and pull a Dolt database just like a Git repository. It is MySQL-compatible, meaning any MySQL client can connect to Dolt. Git versions files, Dolt versions tables.

Dolt is written in Go and is distributed as a single binary (~103MB). It is developed by DoltHub. There is also DoltHub (a place to share Dolt databases publicly), DoltLab (self-hosted DoltHub), Hosted Dolt (managed Dolt server), and Doltgres (a Postgres-compatible variant, currently in Beta).

## 2. What Dolt Can Do?

- Full MySQL-compatible SQL database (connect with any MySQL client)
- Git-like version control for database tables (branch, merge, diff, commit, clone, push, pull)
- Time travel queries (query data at any point in history)
- Diff tables between any two commits, branches, or tags
- Blame individual rows to see who last modified them
- Merge branches with conflict resolution
- Fork and clone databases (like GitHub repos)
- Binlog replication from an existing MySQL database (every write becomes a Dolt commit)
- Foreign keys, secondary indexes, triggers, check constraints, stored procedures
- Schema and data versioning together
- Built-in MySQL-compatible server (`dolt sql-server`)
- Built-in MySQL-compatible client (`dolt sql`)
- Cherry-pick and revert commits
- Export/import CSV files
- Garbage collection for unreferenced data

## 3. How It Works?

Dolt stores data using a content-addressed Merkle DAG (similar to Git's internal structure but optimized for tables instead of files). Each commit is a snapshot of the entire database at a point in time.

Version control is exposed in two ways:
- **CLI**: Git-like commands (`dolt commit`, `dolt branch`, `dolt merge`, etc.) that target tables instead of files.
- **SQL**: System tables (e.g., `dolt_log`, `dolt_diff`, `dolt_status`) for read operations and stored procedures (e.g., `dolt_commit()`, `dolt_checkout()`, `dolt_merge()`) for write operations. The naming follows `dolt_<command>`.

Dolt runs a MySQL-compatible server (`dolt sql-server`) on port 3306 by default. Any MySQL client can connect to it. Databases are stored as directories on disk. Dolt commits are separate from SQL transaction commits — you can use `@@dolt_transaction_commit` to auto-create Dolt commits on every transaction.

Remotes work like Git remotes. You can push/pull to DoltHub, DoltLab, or any file-based remote.

## 4. Main Commands and How to Use

### Installation
```bash
sudo bash -c 'curl -L https://github.com/dolthub/dolt/releases/latest/download/install.sh | bash'
```
Or on macOS:
```bash
brew install dolt
```

### Configuration
```bash
dolt config --global --add user.email "you@domain.com"
dolt config --global --add user.name "Your Name"
```

### Core Commands
```bash
dolt init                          # create a new Dolt repository
dolt sql-server                    # start MySQL-compatible server (port 3306)
dolt sql                           # open interactive SQL shell
dolt status                        # show working tree status
dolt add <table>                   # stage table changes
dolt commit -m "message"           # commit staged changes
dolt log                           # show commit history
dolt diff                          # diff working set vs last commit
dolt diff HEAD~1 HEAD              # diff between two commits
dolt branch <name>                 # create a branch
dolt checkout <branch>             # switch branches
dolt merge <branch>                # merge a branch
dolt clone <remote-url>            # clone a remote database
dolt push origin main              # push to remote
dolt pull origin main              # pull from remote
dolt blame <table>                 # show who last modified each row
dolt cherry-pick <commit>          # apply a specific commit
dolt revert <commit>               # undo a commit
dolt table import -u <table> file  # import CSV into a table
dolt dump                          # export all tables
dolt gc                            # garbage collection
```

### SQL Interface (version control via SQL)
```sql
CALL dolt_add('my_table');
CALL dolt_commit('-m', 'my commit message');
CALL dolt_checkout('-b', 'feature_branch');
CALL dolt_merge('feature_branch');

SELECT * FROM dolt_log;
SELECT * FROM dolt_diff('HEAD~1', 'HEAD', 'my_table');
SELECT * FROM dolt_status;
SELECT * FROM my_table AS OF 'HEAD~3';
```

## 5. Use Cases

- **Data versioning for ML/MLOps**: version training datasets, ensure reproducibility of models
- **Audit logging**: immutable history of every change to every row
- **Configuration management**: version control for game configs, app configs, feature flags
- **Data collaboration**: pull request workflow for data quality (like code review but for data)
- **Cell/scientific simulations**: branch data for different simulation scenarios
- **Application branching**: power applications that need isolated data environments (staging, testing)
- **Regulatory compliance**: track who changed what and when in regulated industries
- **MySQL replica with versioning**: replicate from existing MySQL and get version control for free
- **Data marketplace**: share and distribute datasets via DoltHub
- **Schema migration tracking**: track schema evolution alongside data changes

## 6. Who is Using?

- Companies building ML pipelines needing data versioning and reproducibility
- Game studios managing configuration data across releases
- Biotech/pharma companies running simulations with branched datasets
- Financial services needing audit trails and regulatory compliance
- Data teams using pull-request workflows for data quality
- Open data community sharing datasets on DoltHub (US hospitals, stock tickers, word embeddings, etc.)
- Organizations that need a MySQL-compatible database with built-in change tracking

## 7. Pros

- Git semantics applied to databases (familiar workflow for developers)
- Full MySQL compatibility (drop-in replacement for many use cases)
- Branch, merge, diff, and time travel are first-class features
- Single binary, easy to install and operate
- Can replicate from existing MySQL via binlog replication
- SQL and CLI interfaces for version control operations
- Free public data hosting on DoltHub
- Open source (Apache 2.0)
- Row-level blame and audit trail built in
- Conflict resolution for concurrent data changes
- Doltgres available for Postgres users

## 8. Cons

- Performance overhead compared to vanilla MySQL (version control storage adds cost)
- Larger storage footprint due to maintaining full history
- Not a drop-in replacement for high-throughput OLTP workloads
- Ecosystem is smaller than MySQL/Postgres (fewer tools, integrations, community resources)
- Doltgres (Postgres variant) is still in Beta
- Learning curve for teams unfamiliar with Git concepts applied to databases
- Merge conflicts on data can be harder to resolve than code conflicts
- Not suitable as a primary database for latency-sensitive applications at scale
- Limited support for some advanced MySQL features (replication topology, plugins)
- Smaller company backing compared to established database vendors
