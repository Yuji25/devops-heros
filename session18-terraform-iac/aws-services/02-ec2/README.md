# Amazon EC2 — Compute

## What is EC2?

Amazon Elastic Compute Cloud (EC2) provides virtual servers in AWS.

Users can choose the operating system, CPU, memory, storage and networking configuration required by an application.

## AMI

An Amazon Machine Image (AMI) is a template used to launch an EC2 instance.

It normally contains:

- Operating system
- Software packages
- Configuration

## Instance Types

Instance types define the CPU, memory, networking and hardware characteristics of an EC2 instance.

Different families are optimized for workloads such as:

- General purpose
- Compute intensive
- Memory intensive
- Storage intensive
- Accelerated computing

## Key Pairs

Key pairs are commonly used for secure SSH authentication to Linux EC2 instances.

The private key must be stored securely.

## Security Groups

A Security Group acts as a stateful virtual firewall for an EC2 instance.

Rules control allowed inbound and outbound traffic.

Example:

```text
SSH   → TCP 22
HTTP  → TCP 80
HTTPS → TCP 443
```

## EBS

Amazon Elastic Block Store (EBS) provides block storage volumes for EC2 instances.

EBS volumes can store operating systems, application data and other persistent files.

## Public vs Private IP

A public IP can allow communication with systems on the internet when networking rules permit it.

A private IP is used for communication inside a VPC and is not directly reachable from the public internet.

## Instance Lifecycle

A typical EC2 lifecycle is:

```text
Launch
  ↓
Pending
  ↓
Running
  ↓
Stop / Reboot
  ↓
Running
  ↓
Terminate
```

Stopping normally preserves supported EBS-backed storage, while termination removes the instance.

## Common Use Cases

- Hosting web applications
- Application servers
- Development and testing machines
- Batch processing
- Self-managed databases
- Backend services
- Custom workloads requiring full server control