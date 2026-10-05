import boto3
import json
import os

s3 = boto3.client('s3', region_name='us-east-1')
BUCKET = os.environ.get('BUCKET', 'smarthome-ai-bucket')

def lambda_handler(event, context):
    params = event.get('queryStringParameters', {}) or {}
    doc_key = params.get('key', '')

    headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type',
        'Access-Control-Allow-Methods': 'GET, OPTIONS'
    }

    if not doc_key:
        return {
            'statusCode': 400,
            'headers': headers,
            'body': json.dumps({'error': 'Document key is required'})
        }

    try:
        s3.head_object(Bucket=BUCKET, Key=doc_key)

        download_url = s3.generate_presigned_url(
            'get_object',
            Params={'Bucket': BUCKET, 'Key': doc_key},
            ExpiresIn=604800
        )

        return {
            'statusCode': 200,
            'headers': headers,
            'body': json.dumps({
                'ready': True,
                'url': download_url,
                'key': doc_key
            })
        }

    except Exception:
        return {
            'statusCode': 200,
            'headers': headers,
            'body': json.dumps({
                'ready': False,
                'message': 'Proposal is still being generated...'
            })
        }
