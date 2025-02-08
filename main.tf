## Lambda and CloudWatch Log

resource "aws_iam_policy" "lambda_cloudwatch_policy" {
  name        = "LambdaCloudWatchPolicy"
  description = "Allows Lambda to write logs to CloudWatch."

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"],
        Effect   = "Allow",
        Resource = "arn:aws:logs:{region}:{account-id}:log-group:{log-group-name}" 
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_cloudwatch_attach" {
  policy_arn = aws_iam_policy.lambda_cloudwatch_policy.arn
  role       = aws_iam_role.lambda_execution_role.name
}


## API Gateway and Cloudwatch Log

# Create a CloudWatch Logs Group
resource "aws_cloudwatch_log_group" "api_gateway_log_group" {
  name = "/aws/api-gateway/greeting_api"
}

# Create an access policy for API Gateway to send execution logs to CloudWatch Logs Group
resource "aws_iam_role_policy" "api_gateway_cloudwatch_logs" {
  name   = "ApiGatewayCloudWatchLogs"
  role   = aws_iam_role.api_gateway_execution_role.name
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = ["logs:PutLogEvents", "logs:CreateLogStream"],
        Effect   = "Allow",
        Resource = aws_cloudwatch_log_group.api_gateway_log_group.arn
      }
    ]
  })
}

# Enable access logs in your API Gateway
resource "aws_api_gateway_stage" "api_gateway_stage" {
  # ... (other configurations)

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_log_group.arn
    format          = "[$context.requestId] ($context.identity.sourceIp) \"$context.httpMethod $context.routeKey $context.protocol\" $context.status $context.responseLength $context.requestTime"
  }
}

