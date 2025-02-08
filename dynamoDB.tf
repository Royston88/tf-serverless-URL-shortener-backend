# DynamoDB Table
resource "aws_dynamodb_table" "url_table" {
  name         = "thila_sha_url_shortener"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "short_id"

  attribute {
    name = "short_id"
    type = "S"
  }
}

