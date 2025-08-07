data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = var.source_dir
  source_file = var.source_file
  output_path = var.zip_output
}

resource "aws_lambda_function" "lambda_function" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = var.lambda_name
  role             = var.aws_execution_role_arn
  handler          = var.lambda_handler
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = var.lambda_runtime
  architectures    = var.lambda_architectures
}

resource "aws_apigatewayv2_integration" "service_integration" {
  api_id           = var.api_gateway_id
  integration_type = "AWS_PROXY"

  connection_type        = "INTERNET"
  description            = "Integration for Lambda Service"
  integration_uri        = aws_lambda_function.lambda_function.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "service_route" {
  api_id    = var.api_gateway_id
  route_key = "GET /${var.lambda_name}"

  target             = "integrations/${aws_apigatewayv2_integration.service_integration.id}"
  authorizer_id      = var.authorizer_lambda_id
  authorization_type = "CUSTOM"
}

resource "aws_lambda_permission" "service_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.api_gateway_arn}/*/*"
}
