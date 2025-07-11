resource "null_resource" "function_binary" {
  provisioner "local-exec" {
    command = "cd ${path.module}/../go-service; GOOS=linux GOARCH=arm64 CGOENABLED=0 go build ."
  }
}

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
  depends_on  = [null_resource.function_binary]
  type        = "zip"
  source_file = "${path.module}/../go-service/go-lambda"
  output_path = "service_2.zip"
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
      AUDIENCE = aws_apigatewayv2_stage.v1_stage.invoke_url
    }
  }
}

resource "aws_lambda_function" "service_1_lambda" {
  filename         = data.archive_file.service_1_lambda_zip.output_path
  function_name    = "service-1"
  role             = aws_iam_role.lambda_execution_role.arn
  handler          = "index.handler"
  source_code_hash = data.archive_file.service_1_lambda_zip.output_base64sha256

  runtime = "nodejs20.x"
}

resource "aws_lambda_function" "service_2_lambda" {
  filename      = data.archive_file.service_2_lambda_zip.output_path
  function_name = "service-2"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "go-lambda"

  runtime = "provided.al2"
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
}

resource "aws_apigatewayv2_integration" "service_1_integration" {
  api_id           = aws_apigatewayv2_api.api_gateway.id
  integration_type = "AWS_PROXY"

  connection_type           = "INTERNET"
  content_handling_strategy = "CONVERT_TO_TEXT"
  description               = "Integration for Lambda Authorizer"
  integration_uri           = aws_lambda_function.service_1_lambda.invoke_arn
  integration_method        = "POST"
  passthrough_behavior      = "WHEN_NO_MATCH"
}

resource "aws_apigatewayv2_route" "sevice_1_route" {
  api_id    = aws_apigatewayv2_api.api_gateway.id
  route_key = "GET /service1"

  target             = "integrations/${aws_apigatewayv2_integration.service_1_integration.id}"
  authorizer_id      = aws_apigatewayv2_authorizer.authorizer_lambda.id
  authorization_type = "CUSTOM"
}



resource "aws_apigatewayv2_integration" "service_2_integration" {
  api_id           = aws_apigatewayv2_api.api_gateway.id
  integration_type = "AWS_PROXY"

  connection_type    = "INTERNET"
  description        = "Integration for Lambda Authorizer"
  integration_uri    = aws_lambda_function.service_2_lambda.invoke_arn
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "sevice_2_route" {
  api_id    = aws_apigatewayv2_api.api_gateway.id
  route_key = "GET /service2"

  target             = "integrations/${aws_apigatewayv2_integration.service_2_integration.id}"
  authorizer_id      = aws_apigatewayv2_authorizer.authorizer_lambda.id
  authorization_type = "CUSTOM"
}
