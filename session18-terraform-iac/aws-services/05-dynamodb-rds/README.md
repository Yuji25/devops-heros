# AWS Database Services — DynamoDB & RDS

# DynamoDB

## NoSQL

Amazon DynamoDB is a managed NoSQL database service.

It is designed for applications that require scalable and low-latency access to data.

## Tables

Data in DynamoDB is stored inside tables.

## Items

An item is a single record inside a DynamoDB table.

It is similar to a row in a relational database, although DynamoDB uses a different data model.

## Attributes

Attributes are the individual pieces of data stored inside an item.

Example:

```text
User
├── user_id
├── name
└── email
```

## Partition Key

A partition key is used by DynamoDB to determine how data is distributed.

Every item must contain the table's partition key.

## Sort Key

A sort key can be used together with a partition key to create a composite primary key.

This allows several related items to share the same partition key while remaining uniquely identifiable.

## DynamoDB Use Cases

- High-scale web applications
- Shopping carts
- User sessions
- Gaming
- IoT data
- Serverless applications
- Metadata storage

---

# Amazon RDS

## Relational Database

Amazon Relational Database Service (RDS) is a managed service for relational databases.

It handles much of the infrastructure work involved in operating a database.

## Supported Engines

RDS supports relational database engines such as:

- Amazon Aurora
- PostgreSQL
- MySQL
- MariaDB
- Oracle Database
- Microsoft SQL Server
- IBM Db2

## DB Instances

An RDS DB instance is the managed database environment that provides compute and memory resources for the database engine.

## Security

RDS security can include:

- VPC networking
- Security Groups
- IAM integration where supported
- Encryption
- Secure database credentials
- TLS connections

## Backups

RDS supports automated backups and manual snapshots.

Backups can be used to restore a database when needed.

## Multi-AZ

Multi-AZ deployments improve availability by maintaining database infrastructure in more than one Availability Zone.

They are mainly used for high availability and failover.

## Read Replicas

Read replicas provide additional read-only copies of supported databases.

They can help scale read-heavy workloads.

## RDS Use Cases

- Web application databases
- E-commerce systems
- Business applications
- Content management systems
- Applications requiring SQL and relational data

---

# DynamoDB vs RDS

| DynamoDB | RDS |
|---|---|
| NoSQL | Relational |
| Tables, items, attributes | Tables, rows, columns |
| Designed for scalable key-based access | Designed for SQL workloads |
| Managed serverless-style service | Managed database instances |
| Good for flexible high-scale workloads | Good for relational data and transactions |