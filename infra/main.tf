
resource "aws_apigatewayv2_api" "api_gateway" {
  name          = "distributed-auth-api-gateway"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "v1_stage" {
  api_id = aws_apigatewayv2_api.api_gateway.id
  name   = "v1"
}