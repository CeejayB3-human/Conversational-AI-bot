# ── HTTP API ─────────────────────────────────────────────────────────────────

resource "aws_apigatewayv2_api" "main" {
  name          = "${var.project_name}-smart-home-api"
  protocol_type = "HTTP"
  description   = "Smart Lagos Homes AI Smart Home Advisor API"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_headers = ["*"]
    max_age       = 300
  }

  tags = {
    Project   = "SmartLagosHomes-AI"
    ManagedBy = "Terraform"
  }
}

# ── DEFAULT STAGE ─────────────────────────────────────────────────────────────

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = "$default"
  auto_deploy = true
}

# ── INTEGRATIONS ──────────────────────────────────────────────────────────────

resource "aws_apigatewayv2_integration" "chat" {
  api_id                 = aws_apigatewayv2_api.main.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.slh_chat.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "generate_proposal" {
  api_id                 = aws_apigatewayv2_api.main.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.slh_generate_proposal.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "check_proposal" {
  api_id                 = aws_apigatewayv2_api.main.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.slh_check_proposal.invoke_arn
  payload_format_version = "2.0"
}

# ── ROUTES ────────────────────────────────────────────────────────────────────

resource "aws_apigatewayv2_route" "chat" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "POST /chat"
  target    = "integrations/${aws_apigatewayv2_integration.chat.id}"
}

resource "aws_apigatewayv2_route" "generate_proposal" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "POST /generate-proposal"
  target    = "integrations/${aws_apigatewayv2_integration.generate_proposal.id}"
}

resource "aws_apigatewayv2_route" "check_proposal" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /check-proposal"
  target    = "integrations/${aws_apigatewayv2_integration.check_proposal.id}"
}
