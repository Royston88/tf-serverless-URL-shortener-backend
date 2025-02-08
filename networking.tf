# API Gateway
resource "aws_api_gateway_rest_api" "api" {
  name = "Group1-URL-Shortener"
}

# ACM Certificate
resource "aws_acm_certificate" "cert" {
  domain_name       = "group1-urlshortener.sctp-sandbox.com"
  validation_method = "DNS"
}

# Certificate validation
resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.selected.zone_id
}


# API Gateway Domain Name
resource "aws_api_gateway_domain_name" "shortener" {
  domain_name              = "group1-urlshortener.sctp-sandbox.com"
  regional_certificate_arn = aws_acm_certificate_validation.cert.certificate_arn

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# Route53 Zone
data "aws_route53_zone" "selected" {
  name = "sctp-sandbox.com"
}

# DNS record using Route53
resource "aws_route53_record" "api" {
  name    = aws_api_gateway_domain_name.shortener.domain_name
  type    = "A"
  zone_id = data.aws_route53_zone.selected.zone_id


  alias {
    evaluate_target_health = true
    name                   = aws_api_gateway_domain_name.shortener.regional_domain_name
    zone_id                = aws_api_gateway_domain_name.shortener.regional_zone_id
  }
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "shortener" {
  rest_api_id = aws_api_gateway_rest_api.api.id

  depends_on = [
    aws_api_gateway_rest_api.api,
    aws_api_gateway_resource.newurl,
    aws_api_gateway_method.post_method
  ]

  lifecycle {
    create_before_destroy = true
  }
}

# API Gateway Stage
resource "aws_api_gateway_stage" "shortener" {
  deployment_id = aws_api_gateway_deployment.shortener.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = "prod"
}

# Base Path Mapping
resource "aws_api_gateway_base_path_mapping" "shortener" {
  api_id      = aws_api_gateway_rest_api.api.id
  stage_name  = aws_api_gateway_stage.shortener.stage_name
  domain_name = aws_api_gateway_domain_name.shortener.domain_name
}


############# CREATE URL RESOURCES#####################
resource "aws_api_gateway_resource" "newurl" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "newurl"
}

resource "aws_api_gateway_method" "post_method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.newurl.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "post_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.newurl.id
  http_method             = aws_api_gateway_method.post_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.url_shortener.invoke_arn
}

resource "aws_api_gateway_method_response" "response_200" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.newurl.id
  http_method = aws_api_gateway_method.post_method.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
}

############# POST RESOURCES#####################
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

  request_parameters = {
    "method.request.path.shortid" = true
  }
}

resource "aws_api_gateway_integration" "get_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.geturl.id
  http_method             = aws_api_gateway_method.get_method.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = aws_lambda_function.url_redirect.invoke_arn
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
  http_method = aws_api_gateway_method.get_method.http_method
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
