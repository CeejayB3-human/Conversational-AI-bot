variable "aws_region" {
  description = "AWS region to deploy all resources"
  type        = string
  default     = "us-east-1"
}

variable "aws_account_id" {
  description = "Your AWS account ID"
  type        = string
}

variable "project_name" {
  description = "Project name used for naming all resources"
  type        = string
  default     = "slh"
}

variable "bucket_name" {
  description = "S3 bucket name for catalog and proposals"
  type        = string
  default     = "smarthome-ai-bucket"
}

variable "bedrock_model_id" {
  description = "Claude Sonnet inference profile ARN"
  type        = string
  # Replace with your account-specific ARN after deployment
  default     = "arn:aws:bedrock:us-east-1:ACCOUNT_ID:inference-profile/global.anthropic.claude-sonnet-4-6"
}

variable "knowledge_base_embedding_model" {
  description = "Embedding model ARN for Bedrock Knowledge Base"
  type        = string
  default     = "arn:aws:bedrock:us-east-1::foundation-model/amazon.titan-embed-text-v2:0"
}

variable "docx_layer_arn" {
  description = "ARN of the python-docx Lambda Layer (must be published separately via CloudShell)"
  type        = string
  # See README for instructions on building and publishing this layer
  default     = ""
}
