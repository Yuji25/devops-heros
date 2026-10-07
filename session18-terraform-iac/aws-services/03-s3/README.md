# Amazon S3 — Storage

## What is S3?

Amazon Simple Storage Service (S3) is an object storage service.

It stores data as objects inside buckets and is designed for highly scalable storage.

## Buckets

A bucket is the main container used to store S3 objects.

Bucket names must be globally unique.

## Objects

An object contains the actual data stored in S3.

An object includes:

- Data
- Object key
- Metadata

## Storage Classes

S3 provides different storage classes for different access patterns.

Examples include:

- S3 Standard
- S3 Intelligent-Tiering
- S3 Standard-IA
- S3 One Zone-IA
- S3 Glacier storage classes

The correct class depends on how frequently the data is accessed and how quickly it must be retrieved.

## Versioning

S3 Versioning keeps multiple versions of an object.

It can help recover from accidental overwrites or deletions.

## Lifecycle Policies

Lifecycle rules automatically manage objects over time.

For example:

```text
New Object
    ↓
Standard Storage
    ↓
Move to cheaper storage
    ↓
Archive
    ↓
Delete after retention period
```

## Encryption

S3 supports encryption for stored data and secure transport for data in transit.

Server-side encryption can use AWS-managed or customer-managed keys depending on the requirement.

## Bucket Policies

A bucket policy is a resource-based policy attached to an S3 bucket.

It can control who may access the bucket and which operations are allowed.

## Common Use Cases

- Backups
- Static website files
- Application assets
- Logs
- Data lakes
- Archives
- Media storage
- CI/CD artifacts