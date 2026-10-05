# Smart Lagos Homes — AI Smart Home Advisor & Proposal Generator

> An AI-powered conversational smart home advisor built on Amazon Bedrock and AWS serverless infrastructure. Customers chat with an AI advisor named **Soji**, receive tailored smart home product recommendations, and automatically get a personalised Word document proposal — all without leaving the chat.

---

## Architecture

```
Customer (Browser)
        │
        ▼
AWS Amplify (Chat UI)
        │
        ▼
Amazon API Gateway (HTTP API)
   ┌────┴──────────────────────┐
   │                           │
   ▼                           ▼
POST /chat              GET /check-proposal
POST /generate-proposal
   │
   ▼
AWS Lambda ──────────────────► Amazon Bedrock KB
(slh-chat)                     (slh-smart-home-kb)
     │                              │
     │                    Amazon OpenSearch Serverless
     │                         (Vector Store)
     ▼
Amazon Bedrock
(Claude Sonnet 4.6)
     │
     ▼
[GENERATE_PROPOSAL trigger detected]
     │
     ▼
AWS Lambda
(slh-generate-proposal)
     │
     ├──► python-docx (Word document)
     │
     ▼
Amazon S3
(smarthome-ai-bucket/proposals/)
     │
     ▼
Presigned URL returned in chat
Customer downloads Word proposal
```

---

## AWS Services Used

| Service | Component | Purpose |
|---|---|---|
| Amazon Bedrock | Knowledge Base (slh-smart-home-kb) | Indexes Smart Lagos Homes product catalog for RAG retrieval |
| Amazon Bedrock | Claude Sonnet 4.6 | Powers Soji — conversational AI advisor |
| Amazon Bedrock | Titan Text Embeddings V2 | Converts catalog text to vector embeddings |
| Amazon OpenSearch Serverless | Auto-provisioned vector store | Stores and searches vector embeddings |
| AWS Lambda | slh-chat | Chat handler — KB retrieval, Claude call, proposal trigger |
| AWS Lambda | slh-generate-proposal | Generates Word document proposal |
| AWS Lambda | slh-check-proposal | Polls S3 for completed proposal |
| Amazon S3 | smarthome-ai-bucket | Stores product catalog and generated proposals |
| Amazon API Gateway | slh-smart-home-api | HTTP API with 3 routes |
| AWS Amplify | Chat UI | Hosts customer-facing chat interface |
| AWS IAM | slh-lambda-role | Execution role for all Lambda functions |
| Amazon CloudWatch | Log groups | Execution logs for all 3 Lambda functions |

---

## Repository Structure

```
smart-lagos-homes-ai/
├── README.md
├── terraform/
│   ├── main.tf            # Provider configuration
│   ├── variables.tf       # Input variables
│   ├── outputs.tf         # Output values
│   ├── s3.tf              # S3 bucket and folders
│   ├── iam.tf             # IAM roles and policies
│   ├── bedrock.tf         # Knowledge Base and OpenSearch
│   ├── lambda.tf          # Lambda functions
│   ├── api_gateway.tf     # API Gateway HTTP API
│   └── amplify.tf         # Amplify hosting
├── lambda/
│   ├── slh-chat/
│   │   └── lambda_function.py
│   ├── slh-generate-proposal/
│   │   └── lambda_function.py
│   └── slh-check-proposal/
│       └── lambda_function.py
├── ui/
│   └── index.html         # Chat interface
└── catalog/
    └── smart-lagos-homes-catalog.pdf
```

---

## Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform >= 1.5.0
- Python 3.12
- AWS account with Amazon Bedrock access enabled
  - Claude Sonnet 4.6 model access granted in us-east-1
  - Titan Text Embeddings V2 access granted

---

## Deployment Guide

### Step 1 — Build the python-docx Lambda Layer

Run these commands in AWS CloudShell:

```bash
mkdir -p /tmp/docx-layer/python

pip install python-docx -t /tmp/docx-layer/python --quiet

pip install lxml --target /tmp/docx-layer/python \
  --platform manylinux_2_17_x86_64 \
  --implementation cp \
  --python-version 3.12 \
  --only-binary=:all: --upgrade --quiet

cd /tmp/docx-layer && zip -r docx-layer.zip python/

aws lambda publish-layer-version \
  --layer-name docx-layer \
  --zip-file fileb://docx-layer.zip \
  --compatible-runtimes python3.12 \
  --region us-east-1
```

Copy the `LayerVersionArn` from the output — you will need it in Step 3.

---

### Step 2 — Clone and configure

```bash
git clone https://github.com/YOUR_USERNAME/smart-lagos-homes-ai.git
cd smart-lagos-homes-ai
```

---

### Step 3 — Set Terraform variables

Create a `terraform.tfvars` file inside the `terraform/` folder:

```hcl
aws_account_id = "YOUR_12_DIGIT_ACCOUNT_ID"
aws_region     = "us-east-1"
bucket_name    = "smarthome-ai-bucket"
docx_layer_arn = "arn:aws:lambda:us-east-1:YOUR_ACCOUNT_ID:layer:docx-layer:1"
```

> **Important:** Do not commit `terraform.tfvars` to GitHub — it contains your account ID. It is already in `.gitignore`.

---

### Step 4 — Deploy with Terraform

```bash
cd terraform

terraform init

terraform plan

terraform apply
```

Terraform will create all AWS resources and output the API Gateway URL and Knowledge Base ID.

---

### Step 5 — Upload the product catalog

```bash
aws s3 cp catalog/smart-lagos-homes-catalog.pdf \
  s3://smarthome-ai-bucket/product-catalog/ \
  --region us-east-1
```

---

### Step 6 — Sync the Knowledge Base

1. Go to **Amazon Bedrock → Knowledge bases** in the AWS console
2. Click on **slh-smart-home-kb**
3. Click **Sync** and wait for it to complete (2-3 minutes)
4. Test with the Knowledge Base test interface:
   - *"What is the price of the 3KVA smart inverter?"*
   - *"What package do you recommend for a 3 bedroom flat with a budget of 600,000 naira?"*

---

### Step 7 — Update the UI with your API URL

Open `ui/index.html` and find this line:

```javascript
const API = 'https://YOUR_API_GATEWAY_URL';
```

Replace `YOUR_API_GATEWAY_URL` with the `api_gateway_endpoint` value from the Terraform output.

---

### Step 8 — Deploy the UI to Amplify

```bash
cd ui
zip -j ui.zip index.html
```

Then go to **AWS Amplify → Apps → smart-lagos-homes-ai-advisor** in the console and use manual deployment to upload `ui.zip`.

---

### Step 9 — Test end to end

Open the Amplify URL and test with these prompts:

**Message 1:**
```
I have a 3 bedroom flat in Lekki. NEPA cuts power 12 hours daily. Budget is 700,000 naira.
```

**Message 2:**
```
I also want security cameras and a smart gate lock for my compound.
```

**Message 3:**
```
Yes please recommend the best packages for my situation.
```

After message 3, Soji will automatically generate and deliver a Word document proposal in the chat.

---

## How It Works

1. Customer types a message describing their home and needs
2. `slh-chat` Lambda searches the Knowledge Base for relevant products
3. Claude Sonnet generates Soji's response with recommendations
4. After the 3rd exchange, Claude includes `[GENERATE_PROPOSAL]` in its response
5. Lambda detects the trigger, generates a Word document proposal using python-docx
6. Proposal is saved to S3 and a presigned download URL is returned
7. A gold download card appears in the chat — customer clicks to download

---

## Environment Variables

| Variable | Lambda | Description |
|---|---|---|
| `KB_ID` | slh-chat, slh-generate-proposal | Bedrock Knowledge Base ID |
| `MODEL_ID` | slh-chat, slh-generate-proposal | Claude Sonnet inference profile ARN |
| `BUCKET` | All three | S3 bucket name |

These are set automatically by Terraform from your `variables.tf` values.

---

## Estimated AWS Costs

| Service | Estimated Monthly Cost |
|---|---|
| Amazon Bedrock (Claude Sonnet) | ~$15-30 (based on usage) |
| Amazon Bedrock Knowledge Base | ~$2-5 |
| Amazon OpenSearch Serverless | ~$5-10 |
| AWS Lambda | Negligible |
| Amazon S3 | Negligible |
| Amazon API Gateway | Negligible |
| AWS Amplify | Free tier |
| **Total estimate** | **~$25-50/month** |

---

## Destroying Resources

To remove all AWS resources created by Terraform:

```bash
cd terraform
terraform destroy
```

> **Note:** The S3 bucket must be empty before it can be destroyed. Delete all objects first or run:
> `aws s3 rm s3://smarthome-ai-bucket --recursive`

---

## Built With

- [Amazon Bedrock](https://aws.amazon.com/bedrock/) — Claude Sonnet 4.6 and Knowledge Bases
- [AWS Lambda](https://aws.amazon.com/lambda/) — Serverless compute
- [Amazon API Gateway](https://aws.amazon.com/api-gateway/) — HTTP API
- [Amazon S3](https://aws.amazon.com/s3/) — Object storage
- [AWS Amplify](https://aws.amazon.com/amplify/) — Web hosting
- [Terraform](https://www.terraform.io/) — Infrastructure as Code
- [python-docx](https://python-docx.readthedocs.io/) — Word document generation

---

## Author

Built by **Digitspots Solutions Ltd** as part of the AWS AI Competency Program.

---

## License

MIT License — see [LICENSE](LICENSE) for details.
