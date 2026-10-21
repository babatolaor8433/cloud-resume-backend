data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/build/visitor-count.zip"

  source {
    content  = file("${path.module}/Cloud_resume@/Lambda_function.py")
    filename = "lambda_function.py"
  }
}

resource "aws_dynamodb_table" "visitor_count" {
  name         = "visitor-count"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "Id_string"

  attribute {
    name = "Id_string"
    type = "S"
  }
}

resource "aws_iam_role" "visitor_count" {
  name = "visitor-count-role-bl0qm10a"
  path = "/service-role/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "visitor_logs" {
  name = "AWSLambdaBasicExecutionRole-842ca77e-609b-4b30-a078-23abcf279b05"
  path = "/service-role/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "logs:CreateLogGroup"
        Resource = "arn:aws:logs:us-east-1:586499577551:*"
      },
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:us-east-1:586499577551:log-group:/aws/lambda/visitor-count:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "visitor_logs" {
  role       = aws_iam_role.visitor_count.name
  policy_arn = aws_iam_policy.visitor_logs.arn
}

resource "aws_iam_role_policy" "visitor_update" {
  name = "visitor-count-update"
  role = aws_iam_role.visitor_count.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "dynamodb:UpdateItem"
      Resource = aws_dynamodb_table.visitor_count.arn
    }]
  })
}

resource "aws_lambda_function" "visitor_count" {
  function_name    = "visitor-count"
  role             = aws_iam_role.visitor_count.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.14"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout          = 3
  memory_size      = 128
  architectures    = ["x86_64"]
}

resource "aws_apigatewayv2_api" "visitor" {
  name          = "visitor-count-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_methods = ["GET"]
    allow_origins = ["https://d3b4e36dkb01ow.cloudfront.net"]
    max_age       = 0
  }
}

resource "aws_apigatewayv2_integration" "visitor" {
  api_id                 = aws_apigatewayv2_api.visitor.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.visitor_count.arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "visitor" {
  api_id    = aws_apigatewayv2_api.visitor.id
  route_key = "GET /"
  target    = "integrations/${aws_apigatewayv2_integration.visitor.id}"
}

resource "aws_apigatewayv2_stage" "visitor" {
  api_id      = aws_apigatewayv2_api.visitor.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "visitor" {
  statement_id  = "6e40b412-bbcb-5fef-bcea-03a6f86f4d1a"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.visitor_count.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:us-east-1:586499577551:2q3c9u730k/*/*/"
}
