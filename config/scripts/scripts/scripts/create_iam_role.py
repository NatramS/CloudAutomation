import boto3
import json

def create_iam_role():
    with open('config/aws_config.json') as f:
        config = json.load(f)
    iam = boto3.client('iam')
    assume_role_policy = {
        "Version": "2012-10-17",
        "Statement": [{
            "Effect": "Allow",
            "Principal": {"Service": "ec2.amazonaws.com"},
            "Action": "sts:AssumeRole"
        }]
    }
    role = iam.create_role(
        RoleName=config['iam']['role_name'],
        AssumeRolePolicyDocument=json.dumps(assume_role_policy)
    )
    print(f"IAM Role Created: {role['Role']['RoleName']}")
