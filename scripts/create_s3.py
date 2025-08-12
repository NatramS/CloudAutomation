import boto3
import json

def create_s3_bucket():
    with open('config/aws_config.json') as f:
        config = json.load(f)
    s3 = boto3.client('s3', region_name=config['region'])
    s3.create_bucket(
        Bucket=config['s3']['bucket_name'],
        CreateBucketConfiguration={'LocationConstraint': config['region']}
    )
    print(f"S3 Bucket Created: {config['s3']['bucket_name']}")
