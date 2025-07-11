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

resource "aws_lambda_function" "authorizer_lambda" {
  filename         = data.archive_file.authorizer_lambda_zip.output_path
  function_name    = "distributed-auth-authorizer"
  role             = aws_iam_role.lambda_execution_role.arn
  handler          = "index.handler"
  source_code_hash = data.archive_file.authorizer_lambda_zip.output_base64sha256

  runtime = "nodejs20.x"
}


resource "aws_lambda_function" "service_1_lambda" {
  filename         = data.archive_file.service_1_lambda_zip.output_path
  function_name    = "service-1"
  role             = aws_iam_role.lambda_execution_role.arn
  handler          = "index.handler"
  source_code_hash = data.archive_file.service_1_lambda_zip.output_base64sha256

  runtime = "nodejs20.x"
}

resource "aws_apigatewayv2_api" "api_gateway" {
  name          = "distributed-auth-api-gateway"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "v1_stage" {
  api_id = aws_apigatewayv2_api.api_gateway.id
  name   = "v1"
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

  connection_type    = "INTERNET"
  description        = "Integration for Lambda Authorizer"
  integration_uri    = aws_lambda_function.service_1_lambda.invoke_arn
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "sevice_1_route" {
  api_id    = aws_apigatewayv2_api.api_gateway.id
  route_key = "GET /service1"

  target = "integrations/${aws_apigatewayv2_integration.service_1_integration.id}"
  authorizer_id = aws_apigatewayv2_authorizer.authorizer_lambda.id
  authorization_type = "CUSTOM"
}
