# Amazon VPC — Networking

## What is VPC?

Amazon Virtual Private Cloud (VPC) provides an isolated virtual network inside AWS.

AWS resources such as EC2 instances can be placed inside a VPC.

## CIDR

CIDR notation defines the IP address range available to a network.

Example:

```text
10.0.0.0/16
```

This address range can be divided into smaller subnets.

## Subnets

A subnet is a smaller network created inside a VPC.

Resources are launched inside subnets.

Subnets can be designed as public or private depending on routing.

## Route Tables

A route table contains rules that decide where network traffic should be sent.

Each subnet is associated with a route table.

## Internet Gateway

An Internet Gateway allows communication between a VPC and the internet when the appropriate routes and IP addresses are configured.

A typical public subnet route is:

```text
0.0.0.0/0 → Internet Gateway
```

## NAT Gateway

A NAT Gateway allows resources in a private subnet to initiate outbound internet connections without making those resources directly reachable from the internet.

## Security Groups

Security Groups are stateful firewalls attached to resources such as EC2 instances.

They control allowed inbound and outbound traffic.

## Network ACLs

Network Access Control Lists operate at the subnet level.

They are stateless and can contain both allow and deny rules.

## Public vs Private Subnet

### Public Subnet

A subnet is normally considered public when its route table provides a route to an Internet Gateway.

Resources still need suitable addressing and security rules to communicate with the internet.

### Private Subnet

A private subnet does not provide direct inbound internet access through an Internet Gateway.

Private resources may use a NAT Gateway for outbound access.

## Simple Architecture

```text
Internet
   │
Internet Gateway
   │
Public Subnet
   │
────────────────
   │
Private Subnet
   │
Application / Database
```