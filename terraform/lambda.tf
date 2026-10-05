# ── PACKAGE LAMBDA FUNCTIONS ─────────────────────────────────────────────────

data "archive_file" "slh_chat" {
  type        = "zip"
  source_file = "${path.module}/../lambda/slh-chat/lambda_function.py"
  output_path = "${path.module}/../lambda/slh-chat/slh-chat.zip"
}

data "archive_file" "slh_generate_proposal" {
  type        = "zip"
  source_file = "${path.module}/../lambda/slh-generate-proposal/lambda_function.py"
  output_path = "${path.module}/../lambda/slh-generate-proposal/slh-generate-proposal.zip"
}

data "archive_file" "slh_check_proposal" {
  type        = "zip"
  source_file = "${path.module}/../lambda/slh-check-proposal/lambda_function.py"
  output_path = "${path.module}/../lambda/slh-check-proposal/slh-check-proposal.zip"
}

# ── CLOUDWATCH LOG GROUPS ─────────────────────────────────────────────────────

resource "aws_cloudwatch_log_group" "slh_chat" {
  name              = "/aws/lambda/${var.project_name}-chat"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "slh_generate_proposal" {
  name              = "/aws/lambda/${var.project_name}-generate-proposal"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "slh_check_proposal" {
  name              = "/aws/lambda/${var.project_name}-check-proposal"
  retention_in_days = 30
}

# ── LAMBDA: slh-chat ─────────────────────────────────────────────────────────

resource "aws_lambda_function" "slh_chat" {
  function_name    = "${var.project_name}-chat"
  filename         = data.archive_file.slh_chat.output_path
  source_code_hash = data.archive_file.slh_chat.output_base64sha256
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"
  role             = aws_iam_role.lambda_role.arn
  timeout          = 120
  memory_size      = 1024

  layers = var.docx_layer_arn != "" ? [var.docx_layer_arn] : []

  environment {
    variables = {
      KB_ID    = aws_bedrockagent_knowledge_base.main.id
      MODEL_ID = "arn:aws:bedrock:${var.aws_region}:${var.aws_account_id}:inference-profile/global.anthropic.claude-sonnet-4-6"
      BUCKET   = var.bucket_name
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.slh_chat,
    aws_iam_role_policy_attachment.lambda_basic,
  ]

  tags = {
    Project   = "SmartLagosHomes-AI"
    ManagedBy = "Terraform"
  }
}

# ── LAMBDA: slh-generate-proposal ────────────────────────────────────────────

resource "aws_lambda_function" "slh_generate_proposal" {
  function_name    = "${var.project_name}-generate-proposal"
  filename         = data.archive_file.slh_generate_proposal.output_path
  source_code_hash = data.archive_file.slh_generate_proposal.output_base64sha256
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"
  role             = aws_iam_role.lambda_role.arn
  timeout          = 300
  memory_size      = 512

  layers = var.docx_layer_arn != "" ? [var.docx_layer_arn] : []

  environment {
    variables = {
      KB_ID    = aws_bedrockagent_knowledge_base.main.id
      MODEL_ID = "arn:aws:bedrock:${var.aws_region}:${var.aws_account_id}:inference-profile/global.anthropic.claude-sonnet-4-6"
      BUCKET   = var.bucket_name
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.slh_generate_proposal,
    aws_iam_role_policy_attachment.lambda_basic,
  ]

  tags = {
    Project   = "SmartLagosHomes-AI"
    ManagedBy = "Terraform"
  }
}

# ── LAMBDA: slh-check-proposal ───────────────────────────────────────────────

resource "aws_lambda_function" "slh_check_proposal" {
  function_name    = "${var.project_name}-check-proposal"
  filename         = data.archive_file.slh_check_proposal.output_path
  source_code_hash = data.archive_file.slh_check_proposal.output_base64sha256
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"
  role             = aws_iam_role.lambda_role.arn
  timeout          = 30
  memory_size      = 128

  depends_on = [
    aws_cloudwatch_log_group.slh_check_proposal,
    aws_iam_role_policy_attachment.lambda_basic,
  ]

  tags = {
    Project   = "SmartLagosHomes-AI"
    ManagedBy = "Terraform"
  }
}

# ── API GATEWAY PERMISSIONS ───────────────────────────────────────────────────

resource "aws_lambda_permission" "apigw_chat" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.slh_chat.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}

resource "aws_lambda_permission" "apigw_generate_proposal" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.slh_generate_proposal.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}

resource "aws_lambda_permission" "apigw_check_proposal" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.slh_check_proposal.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}
