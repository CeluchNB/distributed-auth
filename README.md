## Distributed Auth

A sample project to provision AWS infrastructure that implements distributed authentication.

It includes:

- Terraform files for the infrastructure:
  - API Gateway
  - 2 API Gateway routes with an authorizer
  - A lambda for the authorizer
  - 2 lambdas for the API Gateway routes
  - S3 bucket for lambda code
- A lambda to validate an Auth0 JWT
- Two lambas that return HTTP responses

### Current Steps To Work

- `terraform plan`
- `terraform apply`
- Take api_gateway_url output and update client env
- Create API in auth0 with api_gateway_url
- Grant new auth0 API access to "My API" in "Machine to Machine Applications" (probably a better way to implement this)
