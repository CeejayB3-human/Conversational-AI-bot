# ── S3 BUCKET ────────────────────────────────────────────────────────────────

resource "aws_s3_bucket" "main" {
  bucket = var.bucket_name

  tags = {
    Project = "SmartLagosHomes-AI"
    ManagedBy = "Terraform"
  }
}

resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_public_access_block" "main" {
  bucket                  = aws_s3_bucket.main.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ── BUCKET FOLDERS (placeholder objects) ────────────────────────────────────

resource "aws_s3_object" "product_catalog_folder" {
  bucket  = aws_s3_bucket.main.id
  key     = "product-catalog/"
  content = ""
}

resource "aws_s3_object" "proposals_folder" {
  bucket  = aws_s3_bucket.main.id
  key     = "proposals/"
  content = ""
}

# ── UPLOAD PRODUCT CATALOG ───────────────────────────────────────────────────
# Upload the catalog PDF after bucket creation
# aws s3 cp ../catalog/smart-lagos-homes-catalog.pdf s3://smarthome-ai-bucket/product-catalog/

# ── CORS CONFIGURATION ───────────────────────────────────────────────────────

resource "aws_s3_bucket_cors_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}
