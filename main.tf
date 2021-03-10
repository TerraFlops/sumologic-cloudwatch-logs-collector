# Retrieve the region/account details
data "aws_caller_identity" "default" {}
data "aws_region" "default" {}

# Retrieve the log group ARN
data "aws_cloudwatch_log_group" "source" {
  name = var.log_group_name
  retention_in_days = 0
}

locals {
  log_group_name_snake = regex("[0-9A-Za-z]+", join("", [ for element in split("/",replace(replace(var.log_group_name, "_", "/"), "-", "/")): title(element) ]))
  log_prefix_snake = var.log_stream_prefix == null ? "" : regex("[0-9A-Za-z]+", join("", [ for element in split("/",replace(replace(var.log_stream_prefix, "_", "/"), "-", "/")): title(element) ]))
  log_stream_prefix = var.log_stream_prefix == null ? "" : var.log_stream_prefix
  lambda_filename = "${path.module}/collector.js"
  lambda_hash = filesha512(local.lambda_filename)
  lambda_archive_filename = "/tmp/lambda-collector-js-${local.lambda_hash}.zip"
}

# Create Sumo Logic collector
resource "sumologic_collector" "collector" {
  name = "Terraform${local.log_group_name_snake}${local.log_prefix_snake}${data.aws_caller_identity.default.account_id}"
  description = "AWS Account ${data.aws_caller_identity.default.account_id} HTTP Collector (${local.log_group_name_snake})"
}

# Create Sumo Logic data source
resource "sumologic_http_source" "source" {
  name = "${var.log_group_name}${local.log_stream_prefix}"
  description = "AWS Account ${data.aws_caller_identity.default.account_id} HTTP Source (${local.log_group_name_snake})"
  category = var.category
  collector_id = sumologic_collector.collector.id
}

# Create IAM role that Sumo Logic will use the read the source bucket
resource "aws_iam_role" "collector" {
  name = "SumoLogicCloudWatchCollector${local.log_group_name_snake}${local.log_prefix_snake}"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

# Allow Lambda to assume the IAM role
data "aws_iam_policy_document" "lambda_assume_role" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      identifiers = [
        "lambda.amazonaws.com"
      ]
      type = "Service"
    }
  }
}

# Create IAM policy granting the Lambda function to execute and create execution logs
data "aws_iam_policy_document" "lambda_execution" {
  version = "2012-10-17"
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    effect = "Allow"
    resources = [
      "*"
    ]
  }
}

# Attach IAM policy to the role
resource "aws_iam_role_policy" "lambda_execution" {
  name = "SumoLogicHttpCollector${local.log_group_name_snake}LambdaExecutionPolicy"
  role = aws_iam_role.collector.id
  policy = data.aws_iam_policy_document.lambda_execution.json
}

# Allow CloudWatch to invoke the Lambda function
resource "aws_lambda_permission" "collector" {
  statement_id = "AllowExecutionFromCloudWatchLogs"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.collector.function_name
  principal = "logs.${data.aws_region.default.name}.amazonaws.com"
  source_arn = data.aws_cloudwatch_log_group.source.arn
}

# Compress the Lambda function into a ZIP file
data "archive_file" "collector" {
  type = "zip"
  source_file = local.lambda_filename
  output_path = local.lambda_archive_filename
}

# Create Lambda function to send CloudWatch logs to the Sumo Logic HTTP collector
resource "aws_lambda_function" "collector" {
  function_name = "SumoLogicHttpCollector${local.log_group_name_snake}${local.log_prefix_snake}"
  description = "Sends CloudWatch Logs to Sumo Logic HTTP Collector"
  runtime = "nodejs12.x"
  handler = "collector.handler"
  role = aws_iam_role.collector.arn
  filename = data.archive_file.collector.output_path
  source_code_hash = local.lambda_hash
  timeout = 900
  environment {
    variables = {
      SUMO_ENDPOINT = sumologic_http_source.source.url
      LOG_STREAM_PREFIX = local.log_stream_prefix
    }
  }
}

resource "aws_cloudwatch_log_subscription_filter" "collector" {
  name = "SumoLogicSubscription${local.log_group_name_snake}${local.log_prefix_snake}"
  log_group_name = data.aws_cloudwatch_log_group.source.name
  destination_arn = aws_lambda_function.collector.arn
  filter_pattern = ""
  distribution = "ByLogStream"
}