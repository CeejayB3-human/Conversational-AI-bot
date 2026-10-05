# ── OPENSEARCH SERVERLESS (Vector Store) ─────────────────────────────────────

resource "aws_opensearchserverless_security_policy" "kb_encryption" {
  name        = "${var.project_name}-kb-encryption"
  type        = "encryption"
  description = "Encryption policy for Smart Lagos Homes KB vector store"
  policy = jsonencode({
    Rules = [{
      ResourceType = "collection"
      Resource     = ["collection/${var.project_name}-kb-vectors"]
    }]
    AWSOwnedKey = true
  })
}

resource "aws_opensearchserverless_security_policy" "kb_network" {
  name        = "${var.project_name}-kb-network"
  type        = "network"
  description = "Network policy for Smart Lagos Homes KB vector store"
  policy = jsonencode([{
    Rules = [
      {
        ResourceType = "collection"
        Resource     = ["collection/${var.project_name}-kb-vectors"]
      },
      {
        ResourceType = "dashboard"
        Resource     = ["collection/${var.project_name}-kb-vectors"]
      }
    ]
    AllowFromPublic = true
  }])
}

resource "aws_opensearchserverless_access_policy" "kb_data" {
  name        = "${var.project_name}-kb-data-access"
  type        = "data"
  description = "Data access policy for Bedrock Knowledge Base"
  policy = jsonencode([{
    Rules = [
      {
        ResourceType = "index"
        Resource     = ["index/${var.project_name}-kb-vectors/*"]
        Permission   = ["aoss:*"]
      },
      {
        ResourceType = "collection"
        Resource     = ["collection/${var.project_name}-kb-vectors"]
        Permission   = ["aoss:*"]
      }
    ]
    Principal = [
      aws_iam_role.bedrock_kb_role.arn,
      "arn:aws:iam::${var.aws_account_id}:root"
    ]
  }])
}

resource "aws_opensearchserverless_collection" "kb_vectors" {
  name        = "${var.project_name}-kb-vectors"
  type        = "VECTORSEARCH"
  description = "Vector store for Smart Lagos Homes product catalog"

  depends_on = [
    aws_opensearchserverless_security_policy.kb_encryption,
    aws_opensearchserverless_security_policy.kb_network,
    aws_opensearchserverless_access_policy.kb_data,
  ]

  tags = {
    Project   = "SmartLagosHomes-AI"
    ManagedBy = "Terraform"
  }
}

# ── BEDROCK KNOWLEDGE BASE ────────────────────────────────────────────────────

resource "aws_bedrockagent_knowledge_base" "main" {
  name        = "${var.project_name}-smart-home-kb"
  description = "Smart Lagos Homes product catalog and recommendation rules"
  role_arn    = aws_iam_role.bedrock_kb_role.arn

  knowledge_base_configuration {
    type = "VECTOR"
    vector_knowledge_base_configuration {
      embedding_model_arn = var.knowledge_base_embedding_model
    }
  }

  storage_configuration {
    type = "OPENSEARCH_SERVERLESS"
    opensearch_serverless_configuration {
      collection_arn    = aws_opensearchserverless_collection.kb_vectors.arn
      vector_index_name = "bedrock-knowledge-base-default-index"
      field_mapping {
        vector_field   = "bedrock-knowledge-base-default-vector"
        text_field     = "AMAZON_BEDROCK_TEXT_CHUNK"
        metadata_field = "AMAZON_BEDROCK_METADATA"
      }
    }
  }

  depends_on = [
    aws_opensearchserverless_collection.kb_vectors,
    aws_iam_role_policy_attachment.bedrock_kb_bedrock,
    aws_iam_role_policy_attachment.bedrock_kb_s3,
  ]

  tags = {
    Project   = "SmartLagosHomes-AI"
    ManagedBy = "Terraform"
  }
}

# ── KNOWLEDGE BASE DATA SOURCE ────────────────────────────────────────────────

resource "aws_bedrockagent_data_source" "catalog" {
  knowledge_base_id = aws_bedrockagent_knowledge_base.main.id
  name              = "${var.project_name}-product-catalog"
  description       = "Smart Lagos Homes product catalog PDF"

  data_source_configuration {
    type = "S3"
    s3_configuration {
      bucket_arn              = aws_s3_bucket.main.arn
      inclusion_prefixes      = ["product-catalog/"]
    }
  }

  vector_ingestion_configuration {
    chunking_configuration {
      chunking_strategy = "FIXED_SIZE"
      fixed_size_chunking_configuration {
        max_tokens         = 300
        overlap_percentage = 20
      }
    }
  }
}
