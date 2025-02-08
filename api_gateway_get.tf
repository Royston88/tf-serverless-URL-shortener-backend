resource "aws_api_gateway_resource" "geturl" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "{shortid}"
}

resource "aws_api_gateway_method" "get_method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.geturl.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "get_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.geturl.id
  http_method             = aws_api_gateway_method.get_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.retrieve_url.invoke_arn
  request_templates = {
    "application/json" = <<EOF
    { 
      "short_id": "$input.params('shortid')" 
    }
    EOF
  }
}

resource "aws_api_gateway_method_response" "response_302" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.geturl.id
  http_method = "GET"
  status_code = "302"

  response_parameters = {
    "method.response.header.Location" = true
  }
}

resource "aws_api_gateway_integration_response" "get_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.geturl.id
  http_method = aws_api_gateway_method.get_method.http_method
  status_code = aws_api_gateway_method_response.response_302.status_code

  response_parameters = {
    "method.response.header.Location" = "integration.response.body.location"
  }
  depends_on = [
    aws_api_gateway_integration.get_integration
  ]
}