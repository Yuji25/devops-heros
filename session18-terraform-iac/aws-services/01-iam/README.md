
# AWS IAM — Governance

## What is IAM?

AWS Identity and Access Management (IAM) controls who can access AWS resources and what actions they are allowed to perform.

IAM helps manage authentication and authorization in an AWS account.

## Users

An IAM user represents a person or application that needs access to AWS.

A user can have permissions and credentials such as console passwords or access keys.

## Groups

An IAM group is a collection of IAM users.

Permissions can be assigned to a group so that multiple users can receive the same permissions.

Example:

```text
Developers Group
├── Developer 1
├── Developer 2
└── Developer 3
```

## Roles

An IAM role is an identity that can be temporarily assumed.

Roles are commonly used by:

- EC2 instances
- Lambda functions
- AWS services
- Users requiring temporary permissions
- Cross-account access

Roles are preferred over storing long-term credentials inside applications.

## Policies

IAM policies are JSON documents that define allowed or denied actions.

A policy can specify:

- Actions
- Resources
- Conditions
- Whether access is allowed or denied

## Permissions

Permissions determine which AWS operations an identity can perform on particular resources.

For example, a user may have permission to read objects from one S3 bucket but not delete them.

## Least Privilege

Least privilege means granting only the permissions required to perform a task and nothing more.

This reduces the damage that can occur if credentials are misused or compromised.

## IAM Best Practices

- Do not use the root account for daily work.
- Enable MFA.
- Follow least privilege.
- Prefer IAM roles and temporary credentials.
- Do not commit access keys to source control.
- Rotate or remove unused credentials.
- Use groups to manage permissions for multiple users.
- Review permissions regularly.

## Common Use Cases

- Giving developers controlled AWS access
- Allowing EC2 to access S3
- Providing Lambda permissions
- Cross-account access
- CI/CD access to AWS
- Managing administrator and read-only access