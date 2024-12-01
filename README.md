# Terraform VPC Setup

This repository contains a Terraform configuration for setting up an Amazon VPC with multiple public and private subnets in AWS.

## Components
- VPC: A Virtual Private Cloud that acts as a container for your AWS resources.
- Public Subnets: Public subnets that allow internet access.
- Private Subnets: Private subnets that do not have direct internet access.
- Internet Gateway: An Internet Gateway to provide internet connectivity to the public subnets.
- Routing Tables: Separate routing tables for public and private subnets.

## Usage Commands

1. Clone the repository:
   git clone <repository_url>
   cd <repository_directory>

2. Initialize Terraform directory:
   terraform init

3. Validate the configuration:
   terraform validate

4. Plan the deployment:
   terraform plan

5. Apply the configuration:
   terraform apply

6. Destroy the resources (if needed):
   terraform destroy


## Configuration

Customize the VPC configuration by modifying the `variables.tf` file or by providing a `terraform.tfvars` file with your desired values[4].

## Importing AWS ACM Certificate

To import an SSL/TLS certificate into AWS Certificate Manager (ACM), use the following command:

```bash
aws acm import-certificate --certificate fileb://certificate.pem \
                           --private-key fileb://private_key.pem \
                           --certificate-chain fileb://certificate_chain.pem \
                           --region us-east-1
```

Replace:
- `certificate.pem` with the path to your certificate file.
- `private_key.pem` with the path to your private key file.
- `certificate_chain.pem` with the path to your certificate chain file.


## Requirements
- Terraform installed on your local machine.
- AWS credentials configured to allow access to your AWS account.

## Variables
Make sure to configure the terraform.tfvars file with appropriate values for the variables used in your Terraform scripts.
