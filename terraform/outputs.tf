output "s3_bucket_name" {
  description = "S3 bucket name for catalog and proposals"
  value       = aws_s3_bucket.main.bucket
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.main.arn
}

output "knowledge_base_id" {
  description = "Bedrock Knowledge Base ID — needed for Lambda environment variables"
  value       = aws_bedrockagent_knowledge_base.main.id
}

output "knowledge_base_arn" {
  description = "Bedrock Knowledge Base ARN"
  value       = aws_bedrockagent_knowledge_base.main.arn
}

output "opensearch_collection_endpoint" {
  description = "OpenSearch Serverless collection endpoint"
  value       = aws_opensearchserverless_collection.kb_vectors.collection_endpoint
}

output "api_gateway_endpoint" {
  description = "API Gateway invoke URL — paste this into the UI HTML file"
  value       = aws_apigatewayv2_stage.default.invoke_url
}

output "lambda_chat_arn" {
  description = "slh-chat Lambda ARN"
  value       = aws_lambda_function.slh_chat.arn
}

output "lambda_generate_proposal_arn" {
  description = "slh-generate-proposal Lambda ARN"
  value       = aws_lambda_function.slh_generate_proposal.arn
}

output "lambda_check_proposal_arn" {
  description = "slh-check-proposal Lambda ARN"
  value       = aws_lambda_function.slh_check_proposal.arn
}

output "lambda_role_arn" {
  description = "IAM role ARN used by all Lambda functions"
  value       = aws_iam_role.lambda_role.arn
}

output "amplify_app_id" {
  description = "Amplify app ID — use this to deploy the UI"
  value       = aws_amplify_app.main.id
}

output "amplify_default_domain" {
  description = "Amplify default domain for the chat interface"
  value       = aws_amplify_app.main.default_domain
}

output "next_steps" {
  description = "Manual steps required after terraform apply"
  value = <<-EOT
    ============================================================
    NEXT STEPS AFTER TERRAFORM APPLY
    ============================================================
    1. Upload product catalog to S3:
       aws s3 cp catalog/smart-lagos-homes-catalog.pdf s3://${aws_s3_bucket.main.bucket}/product-catalog/

    2. Sync the Knowledge Base in Bedrock console:
       Knowledge Base ID: ${aws_bedrockagent_knowledge_base.main.id}

    3. Update the API URL in ui/index.html:
       Replace API endpoint with: ${aws_apigatewayv2_stage.default.invoke_url}

    4. Deploy the UI to Amplify:
       cd ui && zip -j ui.zip index.html
       Upload ui.zip via Amplify console manual deployment

    5. Test the full solution end to end
    ============================================================
  EOT
}
