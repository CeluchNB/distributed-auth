
variables {
    auth0_domain = "test.com"
    google_client_id = "1234"
    google_client_secret = "testsecret"
}

run "valid_lambda" {
    command = plan

    assert {
        condition = aws_lambda_function.authorizer_lambda.function_name == "distributed-auth-authorizer"
        error_message = "Authorizer Lambda not created correctly"
    }
}

run "valid_api_gateway" {
    command = plan

    assert {
        condition = aws_apigatewayv2_api.api_gateway.name == "distributed-auth-api-gateway"
        error_message = "API Gateway not created correctly"
    }

     assert {
        condition = aws_apigatewayv2_stage.v1_stage.name == "v1"
        error_message = "Gateway Stage not created correctly"
    }
}
