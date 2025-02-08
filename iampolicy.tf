# IAM Role for Lambda
resource "aws_iam_role" "lambda_role_thila_sha" {
  name = "lambda_execution_role_thila_sha"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF

  tags = {
    Owner   = "thila_sha"
    Purpose = "ClassActivity_3.3"
  }
}

# IAM Policy for Lambda to Access DynamoDB
resource "aws_iam_policy" "lambda_dynamodb_policy_thila_sha" {
  name        = "lambda_dynamodb_policy_thila_sha"
  description = "Policy for Lambda to access DynamoDB for thila_sha"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:PutItem",
        "dynamodb:GetItem"
      ],
      "Resource": "${aws_dynamodb_table.url_table.arn}"
    }
  ]
}
EOF

  tags = {
    Owner   = "thila_sha"
    Purpose = "ClassActivity_3.3"
  }
}

# IAM Policy for Lambda Logging
resource "aws_iam_policy" "lambda_logging_policy_thila_sha" {
  name        = "lambda_logging_policy_thila_sha"
  description = "Policy for Lambda to write logs to CloudWatch for thila_sha"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    }
  ]
}
EOF

  tags = {
    Owner   = "thila_sha"
    Purpose = "ClassActivity_3.3"
  }
}

# Attach Policies to Role
resource "aws_iam_role_policy_attachment" "lambda_dynamodb_attach_thila_sha" {
  policy_arn = aws_iam_policy.lambda_dynamodb_policy_thila_sha.arn
  role       = aws_iam_role.lambda_role_thila_sha.name
}

resource "aws_iam_role_policy_attachment" "lambda_logging_attach_thila_sha" {
  policy_arn = aws_iam_policy.lambda_logging_policy_thila_sha.arn
  role       = aws_iam_role.lambda_role_thila_sha.name
}
