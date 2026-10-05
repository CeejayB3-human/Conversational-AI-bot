# ── AMPLIFY APP ───────────────────────────────────────────────────────────────
# Note: Amplify manual ZIP deployment is configured here.
# After terraform apply, go to AWS Amplify console and upload ui/index.html
# packaged as a ZIP file using the manual deployment option.

resource "aws_amplify_app" "main" {
  name        = "smart-lagos-homes-ai-advisor"
  description = "Smart Lagos Homes AI Smart Home Advisor Chat Interface"

  # Custom headers for security
  custom_headers = <<-EOT
    customHeaders:
      - pattern: '**/*'
        headers:
          - key: 'Strict-Transport-Security'
            value: 'max-age=31536000; includeSubDomains'
          - key: 'X-Frame-Options'
            value: 'DENY'
          - key: 'X-Content-Type-Options'
            value: 'nosniff'
  EOT

  tags = {
    Project   = "SmartLagosHomes-AI"
    ManagedBy = "Terraform"
  }
}

resource "aws_amplify_branch" "main" {
  app_id      = aws_amplify_app.main.id
  branch_name = "main"
  stage       = "PRODUCTION"

  tags = {
    Project   = "SmartLagosHomes-AI"
    ManagedBy = "Terraform"
  }
}
