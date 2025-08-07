data "archive_file" "authorizer_lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../authorizer"
  output_path = "authorizer.zip"
}

resource "aws_cloudwatch_log_group" "authorizer_log_group" {
  name              = "/aws/lambda/distributed-auth-authorizer"
  retention_in_days = 14

  tags = {
    Environment = "production"
    Function    = "distributed-auth-authorizer"
  }
}

resource "aws_lambda_function" "authorizer_lambda" {
  filename         = data.archive_file.authorizer_lambda_zip.output_path
  function_name    = "distributed-auth-authorizer"
  role             = aws_iam_role.lambda_execution_role.arn
  handler          = "index.handler"
  source_code_hash = data.archive_file.authorizer_lambda_zip.output_base64sha256

  runtime = "nodejs20.x"

  environment {
    variables = {
      AUDIENCE     = aws_apigatewayv2_stage.v1_stage.invoke_url
      AUTH0_DOMAIN = var.auth0_domain
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_log_policy_attachment,
    aws_cloudwatch_log_group.service_1_log_group
  ]
}

resource "aws_cloudwatch_log_group" "service_1_log_group" {
  name              = "/aws/lambda/service-1"
  retention_in_days = 14

  tags = {
    Environment = "production"
    Function    = "service-1"
  }
}

resource "aws_apigatewayv2_api" "api_gateway" {
  name          = "distributed-auth-api-gateway"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_headers = ["authorization"]
  }
}

resource "aws_apigatewayv2_stage" "v1_stage" {
  api_id      = aws_apigatewayv2_api.api_gateway.id
  name        = "v1"
  auto_deploy = true
}

resource "aws_apigatewayv2_authorizer" "authorizer_lambda" {
  api_id          = aws_apigatewayv2_api.api_gateway.id
  authorizer_type = "REQUEST"
  authorizer_uri  = aws_lambda_function.authorizer_lambda.invoke_arn

  identity_sources                  = ["$request.header.Authorization"]
  name                              = "gateway-authorizer"
  authorizer_payload_format_version = "2.0"
  enable_simple_responses           = true
}

resource "aws_lambda_permission" "authorizer_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.authorizer_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api_gateway.execution_arn}/*/*"
}


module "lambda_route_1" {
  source = "./modules/lambda_route"

  source_dir             = "${path.module}/../node-service"
  zip_output             = "service_1.zip"
  lambda_name            = "service-1"
  lambda_handler         = "index.handler"
  lambda_runtime         = "nodejs20.x"
  aws_execution_role_arn = aws_iam_role.lambda_execution_role.arn
  authorizer_lambda_id   = aws_apigatewayv2_authorizer.authorizer_lambda.id
  api_gateway_arn        = aws_apigatewayv2_api.api_gateway.execution_arn
  api_gateway_id         = aws_apigatewayv2_api.api_gateway.id
}


module "lambda_route_2" {
  source = "./modules/lambda_route"

  source_file            = "${path.module}/../go-service/bootstrap"
  zip_output             = "service_2.zip"
  lambda_name            = "service-2"
  lambda_handler         = "bootstrap"
  lambda_runtime         = "provided.al2023"
  lambda_architectures   = ["arm64"]
  aws_execution_role_arn = aws_iam_role.lambda_execution_role.arn
  authorizer_lambda_id   = aws_apigatewayv2_authorizer.authorizer_lambda.id
  api_gateway_arn        = aws_apigatewayv2_api.api_gateway.execution_arn
  api_gateway_id         = aws_apigatewayv2_api.api_gateway.id
}

output "api_gateway_url" {
  value = aws_apigatewayv2_stage.v1_stage.invoke_url
}

