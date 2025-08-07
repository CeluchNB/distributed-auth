data "archive_file" "authorizer_lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../authorizer"
  output_path = "authorizer.zip"
}

data "archive_file" "service_1_lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../node-service"
  output_path = "service_1.zip"
}

data "archive_file" "service_2_lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/../go-service/bootstrap"
  output_path = "service_2.zip"
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

resource "aws_lambda_function" "service_1_lambda" {
  filename         = data.archive_file.service_1_lambda_zip.output_path
  function_name    = "service-1"
  role             = aws_iam_role.lambda_execution_role.arn
  handler          = "index.handler"
  source_code_hash = data.archive_file.service_1_lambda_zip.output_base64sha256
  runtime          = "nodejs20.x"

  logging_config {
    application_log_level = "DEBUG"
    log_format            = "JSON"
    system_log_level      = "WARN"
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_log_policy_attachment,
    aws_cloudwatch_log_group.service_1_log_group
  ]
}

resource "aws_lambda_function" "service_2_lambda" {
  filename         = data.archive_file.service_2_lambda_zip.output_path
  function_name    = "service-2"
  role             = aws_iam_role.lambda_execution_role.arn
  handler          = "bootstrap"
  source_code_hash = data.archive_file.service_2_lambda_zip.output_base64sha256

  runtime       = "provided.al2023"
  architectures = ["arm64"]
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


resource "aws_apigatewayv2_integration" "service_1_integration" {
  api_id           = aws_apigatewayv2_api.api_gateway.id
  integration_type = "AWS_PROXY"

  connection_type        = "INTERNET"
  description            = "Integration for Lambda Service 1"
  integration_uri        = aws_lambda_function.service_1_lambda.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "service_1_route" {
  api_id    = aws_apigatewayv2_api.api_gateway.id
  route_key = "GET /service1"

  target             = "integrations/${aws_apigatewayv2_integration.service_1_integration.id}"
  authorizer_id      = aws_apigatewayv2_authorizer.authorizer_lambda.id
  authorization_type = "CUSTOM"
}

resource "aws_lambda_permission" "service_1_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.service_1_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api_gateway.execution_arn}/*/*"
}

resource "aws_apigatewayv2_integration" "service_2_integration" {
  api_id           = aws_apigatewayv2_api.api_gateway.id
  integration_type = "AWS_PROXY"

  connection_type        = "INTERNET"
  description            = "Integration for Lambda Service 2"
  integration_uri        = aws_lambda_function.service_2_lambda.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}


resource "aws_apigatewayv2_route" "service_2_route" {
  api_id    = aws_apigatewayv2_api.api_gateway.id
  route_key = "GET /service2"

  target             = "integrations/${aws_apigatewayv2_integration.service_2_integration.id}"
  authorizer_id      = aws_apigatewayv2_authorizer.authorizer_lambda.id
  authorization_type = "CUSTOM"
}

resource "aws_lambda_permission" "service_2_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.service_2_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api_gateway.execution_arn}/*/*"
}

output "api_gateway_url" {
  value = aws_apigatewayv2_stage.v1_stage.invoke_url
}

