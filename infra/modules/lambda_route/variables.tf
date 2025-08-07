variable "source_dir" {
  description = "Path to the folder holding lambda code"
  type        = string
  default     = null
}

variable "source_file" {
  description = "Path to file to zip up"
  type        = string
  default     = null
}

variable "zip_output" {
  description = "Path to zip file"
  type        = string
}

variable "lambda_name" {
  description = "Name of Lambda"
  type        = string
}

variable "lambda_handler" {
  description = "Entrypoint for lambda"
  type        = string
}

variable "lambda_runtime" {
  description = "Runtime for lambda"
  type        = string
}

variable "lambda_architectures" {
  description = "Architecture for lambda"
  type        = set(string)
  default     = ["x86_64"]
}

variable "aws_execution_role_arn" {
  description = "ARN of execution role for AWS Lambda"
  type        = string
}

variable "api_gateway_id" {
  description = "ID of API Gateway"
  type        = string
}

variable "authorizer_lambda_id" {
  description = "ID of authorizer lambda"
  type        = string
}

variable "api_gateway_arn" {
  description = "ARN of API Gateway"
  type        = string
}