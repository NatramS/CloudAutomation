from scripts.create_ec2 import create_ec2
from scripts.create_s3 import create_s3_bucket
from scripts.create_iam_role import create_iam_role

def main():
    create_ec2()
    create_s3_bucket()
    create_iam_role()

if __name__ == "__main__":
    main()
