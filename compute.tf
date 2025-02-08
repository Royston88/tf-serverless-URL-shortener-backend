# ✅ Automatically Zip GET Lambda Python Files
data "archive_file" "lambda_package_get" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_get"  # Zips all Python files in 'lambda_get/' folder
  output_path = "${path.module}/lambda_get.zip"
}

# ✅ Automatically Zip PUT Lambda Python Files
data "archive_file" "lambda_package_put" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_put"  # Zips all Python files in 'lambda_put/' folder
  output_path = "${path.module}/lambda_put.zip"
}

# ✅ Create GET Lambda Function
resource "aws_lambda_function" "my_lambda_get" {
  function_name    = "my_lambda_function_get"
  filename         = data.archive_file.lambda_package_get.output_path
  source_code_hash = data.archive_file.lambda_package_get.output_base64sha256
  role             = "arn:aws:iam::123456789012:role/existing-lambda-role" # Replace with your IAM role ARN
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
}

# ✅ Create PUT Lambda Function
resource "aws_lambda_function" "my_lambda_put" {
  function_name    = "my_lambda_function_put"
  filename         = data.archive_file.lambda_package_put.output_path
  source_code_hash = data.archive_file.lambda_package_put.output_base64sha256
  role             = "arn:aws:iam::123456789012:role/existing-lambda-role" # Replace with your IAM role ARN
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
}

# ✅ Output Lambda Function Names
output "lambda_function_get_name" {
  value = aws_lambda_function.my_lambda_get.function_name
}

output "lambda_function_put_name" {
  value = aws_lambda_function.my_lambda_put.function_name
}
