# eks-demo
# Prerequisite
1 The user who run the terraform code must have appropriate AWS role/privileges to create AWS assets(VPC/RDS/EKS/ALB/WAF) in destination AWS account
2 docker(build the docker image) and kubect (run kubernets command ) and argocd (demo gitops ) and awscli (login to ecr and run codecommit and add eks cluster to kubeconfig file) must be installed on a box which runs the terraform code. Version information as following

![image](https://user-images.githubusercontent.com/36766101/206881819-27a9ee5e-183c-4b57-ad2d-197753878e2c.png)

 




3 I used AWS region us-east-1 for the terraform deployment and wish you keep the same region so no code change needed. 
Since I need to apply ACM for ALB and DNS alias, I need a public Route53 hosted zone so that  ACM DNS verification can be passed. 
Please change the demo_dns_zone variable in variable.tf file accordingly.For example,in following screen snapshot.add www.cmcloudlab458.info and 
run dig command to verify it works as expected. The demo_dns_name.demo_dns_zone  will point to ALB for example, 
for example in variable.tf,the demo_dns_name is ssldemo-eks-alb.The terraform output for ALB name is https://ssldemo-eks-alb.cmcloudlab458.info
![image](https://user-images.githubusercontent.com/36766101/206881858-6b8b7298-17a2-40b4-aef9-7631b565fc0c.png)

![image](https://user-images.githubusercontent.com/36766101/206881841-7bbbc8f9-e052-4db7-814c-c8e9206b8466.png)

![image](https://user-images.githubusercontent.com/36766101/206881871-0b53b2fd-67ed-4489-99c6-689633ff57e8.png)


4 One manual pre-step is create AWS SSM parameter for github token since the github token could not be checkin to github or it will be revoked. I need the github token to demo ArgoCD gitops.(https://argo-cd.readthedocs.io/en/stable/)
aws ssm put-parameter  --name "my-github-token" --type "String" --value "xxxxxxxxx" --region "us-east-1"

5 run terraform init after git clone from repo

Basic function description:
1 Totally 3 ALB created, one is with SSL certificate as required by exposing the application publicly.This one also redirects http request to https. One is the ArgoCD admin console(url and password in the related txt file), and the third one is the demo of  CI/CD pipeline.




5 I added additional RDS access to the pod main.py with RDS access information stored in AWS SSM.

7 I added WAF to protect the 1st ALB and one rule to the WAF so if one IP repeatedly accesses the ALB, will be blocked.
8 I added an ALB access logging to S3 to 1st ALB.You can further analyze web traffic using AWS Athena.  

9 I added codecommit/codebuild/codepipeline to demo that when you change main.py file, codepipeline will automatically build ECR image and modify one public accessible github repo(https://github.com/xiongye77/eks-gitops-demo/blob/main/k8s-deployment.yaml#L23)  which is monitored by ArgoCD (also deployed in the EKS cluster).ArgoCD will sync the new version of docker image to replace the current one.



When synchronization from ArgoCD, it will create new ALB/Ingress/SVC/Deployment/POD based on https://github.com/xiongye77/eks-gitops-demo.git (https://github.com/xiongye77/eks-gitops-demo/blob/main/k8s-deployment.yaml)

Since this pod does not have service account, so its access to SSM is denied  










10 Since the managed nodes are in ASG, more pods (triggered by hpa) deployed to namespaces will trigger EC2 instances added to ASG.
11 horizontal pod autoscaler installed to scale in/out pods according to the amount of traffic.
12 pod use service account assume AWS IAM role to access AWS SSM parameter data
    


kubectl get events




1 AWS VPC created with public subnets and private subnets span multiple AZs. EKS managed node group nodes exist in private subnets. 
2 
