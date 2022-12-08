#!/bin/bash
set -e
codecommit_repo="$1"
AWS_CODECMIT_COMMIT_ID1=$(aws codecommit put-file    --repository-name $codecommit_repo    --branch-name main     --file-content file://./buildspec.yml --file-path  buildspec.yml --name 'ye' --email 'ye.xiong@testmail.com.au'  --cli-binary-format raw-in-base64-out  --query 'commitId' --output text)
echo $AWS_CODECMIT_COMMIT_ID1
AWS_CODECMIT_COMMIT_ID2=$(aws codecommit put-file    --repository-name $codecommit_repo     --branch-name main     --file-content file://./main.py --file-path  main.py --name 'ye' --email 'ye.xiong@testmail.com.au'  --cli-binary-format raw-in-base64-out --parent-commit-id "$AWS_CODECMIT_COMMIT_ID1"  --query 'commitId' --output text)
echo $AWS_CODECMIT_COMMIT_ID2
AWS_CODECMIT_COMMIT_ID3=$(aws codecommit put-file    --repository-name  $codecommit_repo   --branch-name main     --file-content file://./requirements.txt --file-path   requirements.txt --name 'ye' --email 'ye.xiong@testmail.com.au'  --cli-binary-format raw-in-base64-out --parent-commit-id "$AWS_CODECMIT_COMMIT_ID2"  --query 'commitId' --output text)
echo $AWS_CODECMIT_COMMIT_ID3
AWS_CODECMIT_COMMIT_ID4=$(aws codecommit put-file    --repository-name $codecommit_repo     --branch-name main     --file-content file://./Dockerfile --file-path Dockerfile   --name 'ye' --email 'ye.xiong@testmail.com.au'  --cli-binary-format raw-in-base64-out --parent-commit-id "$AWS_CODECMIT_COMMIT_ID3"  --query 'commitId' --output text)
echo $AWS_CODECMIT_COMMIT_ID4
