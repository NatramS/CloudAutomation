import boto3
import json

def create_ec2():
    with open('config/aws_config.json') as f:
        config = json.load(f)
    ec2 = boto3.resource('ec2', region_name=config['region'])
    instance = ec2.create_instances(
        ImageId=config['ec2']['ami_id'],
        InstanceType=config['ec2']['instance_type'],
        KeyName=config['ec2']['key_name'],
        MinCount=1,
        MaxCount=1
    )
    print(f"EC2 Instance Created: {instance[0].id}")
