# eks-demo 

# Prerequisite 
0 I store terraform state file to local filesystem, obviously it is only suitable for test/demo purpose. For any production environment, S3+Dynamodb or Terraform cloud is the desriable option.

1 The user who run the terraform code must have appropriate AWS role/privileges to create AWS assets(VPC/RDS/EKS/ALB/WAF) in destination AWS account.I used AWS region us-east-1 for the terraform deployment and wish you keep the same region so no code change needed.


2 docker(build the docker image) and kubect (run kubernets command ) and argocd (demo gitops ) and awscli (login to ecr and run codecommit and add eks cluster to kubeconfig file),terraform must be installed on a box which runs the terraform code.helm is optional one to check different components' version. Version information as following

![image](https://user-images.githubusercontent.com/36766101/206881819-27a9ee5e-183c-4b57-ad2d-197753878e2c.png)
![image](https://user-images.githubusercontent.com/36766101/207177926-736e9880-8d47-4db2-9c7a-081c2a2af00b.png)

 




3 Since I need to apply SSL certificate from ACM for ALB and use DNS alias for verification, I need a public Route53 hosted zone so that  ACM DNS verification can be passed. Please change the demo_dns_zone variable in variable.tf file accordingly.For example,in following screen snapshot.add www.cmcloudlab458.info and 
run dig command to verify it dns verfication works as expected. The demo_dns_name.demo_dns_zone  will point to ALB for example, 
for example in variable.tf,the demo_dns_name is ssldemo-eks-alb.The terraform output for ALB name is https://ssldemo-eks-alb.cmcloudlab458.info
![image](https://user-images.githubusercontent.com/36766101/206881858-6b8b7298-17a2-40b4-aef9-7631b565fc0c.png)

![image](https://user-images.githubusercontent.com/36766101/206881841-7bbbc8f9-e052-4db7-814c-c8e9206b8466.png)

![image](https://user-images.githubusercontent.com/36766101/206881871-0b53b2fd-67ed-4489-99c6-689633ff57e8.png)


4 One manual pre-step is create AWS SSM parameter for github token since the github token could not be checkin to github or it will be revoked. 
I need the github token to demo ArgoCD gitops.(https://argo-cd.readthedocs.io/en/stable/)
aws ssm put-parameter  --name "my-github-token" --type "String" --value "xxxxxxxxx" --region "us-east-1"

5 run terraform init after git clone from repo



# Basic function description:
1 Totally 3 ALB will be created: 

First one is with SSL certificate as required by exposing the application publicly.This one also redirects http request to https.


![image](https://user-images.githubusercontent.com/36766101/206881975-1a11cc4a-a6b4-4248-b6aa-8f873a35525e.png)
![image](https://user-images.githubusercontent.com/36766101/206881984-44695d2d-07fe-4df1-b087-b5fa6229e5d3.png)

Second one is the ArgoCD admin console(ArgoCD console url is in the argoserver_url.txt and admin user password is in the argoserver_pwd.txt file where are generated by argocd.tf and get_argo_pwd.sh respectively)

The third one will be deployed when sync Argo CD repo and will demonstrate CI/CD pipeline/Gitops pipeline.

2 I added additional RDS access to the pod main.py with RDS access information stored in AWS SSM.

3 I added WAF to protect the 1st ALB and one rule to the WAF so if one IP repeatedly accesses the ALB, will be blocked.
![image](https://user-images.githubusercontent.com/36766101/206881998-9ad65019-ddf5-4102-83c5-a3dac795fbe9.png)


4 I added an ALB access logging to S3 to 1st ALB.You can further analyze web traffic using AWS Athena.  
![image](https://user-images.githubusercontent.com/36766101/206882022-5d0b45c0-3534-41ce-aa4b-24eb6aff642e.png)


5 I added codecommit/codebuild/codepipeline to demo that when you change main.py file, codepipeline will automatically build ECR image and modify one public accessible github repo(https://github.com/xiongye77/eks-gitops-demo/blob/main/k8s-deployment.yaml#L23)  which is monitored by ArgoCD (Also deployed in the EKS cluster in dedicated namespace argocd).ArgoCD will sync the new version of docker image to replace the current one (All gitops resources include ingress/service/deployment/pod in dedicated namespace gitops-demo).
![image](https://user-images.githubusercontent.com/36766101/206882042-9538a03c-b8c9-4f87-a3d9-630d9cb06d36.png)

Argocd login information in following files.
![image](https://user-images.githubusercontent.com/36766101/206882061-f35aa7b9-eced-4dff-940f-609ea91645ad.png)

![image](https://user-images.githubusercontent.com/36766101/206882071-c04688eb-d6f2-4566-a192-2fe556330d24.png)



When synchronization from ArgoCD, it will create new ALB/Ingress/SVC/Deployment/POD based on https://github.com/xiongye77/eks-gitops-demo.git (https://github.com/xiongye77/eks-gitops-demo/blob/main/k8s-deployment.yaml)
![image](https://user-images.githubusercontent.com/36766101/206882176-af9c83ee-2ad6-4dc8-8ad9-03adc2104d17.png)

Since this deployment's pod does not have service account, so its access to SSM is denied  
![image](https://user-images.githubusercontent.com/36766101/206882186-cb39682e-8314-49b3-b751-900b28143efc.png)

The quick workaround here is remove # from line 134 to 137 of iam.tf file and run terraform apply again so EKS nodes' role have the managed policy AmazonSSMManagedInstanceCore which can read from SSM, you can compare that even EKS nodes's role without this policy, the pod wtih service account can still read SSM. 
![image](https://user-images.githubusercontent.com/36766101/206882198-c9ac50b8-b4d3-46e1-8f10-306a9e04c85a.png)

![image](https://user-images.githubusercontent.com/36766101/206882213-ab2d083a-f951-4772-8641-7957c572934b.png)



![image](https://user-images.githubusercontent.com/36766101/206882221-d7a36f1a-a26a-48aa-8e1f-0366ec856d3d.png)


![image](https://user-images.githubusercontent.com/36766101/206882229-438de609-e6d4-426c-b540-c80b04796cb5.png)




6 Since the managed nodes are in ASG, more pods (triggered by hpa) deployed to namespaces will trigger EC2 instances added to ASG.


7 horizontal pod autoscaler installed to scale in/out pods according to the amount of traffic.
![image](https://user-images.githubusercontent.com/36766101/206883527-692e87c2-b803-4de6-8364-87a4900c81e9.png)
We can use one scripe to generate work load which query the kubernetes service IP to cause horizon pod autoscale based on predefined cpu usage (set to 20% to quickly scale out more pods)
![image](https://user-images.githubusercontent.com/36766101/206883706-6ec2ce7b-9597-4af1-8f58-e394f989bbae.png)
![image](https://user-images.githubusercontent.com/36766101/206883795-cba29e66-6289-4cdb-bf9c-7205df6bee03.png)



pod use service account assume AWS IAM role to access AWS SSM parameter data
![image](https://user-images.githubusercontent.com/36766101/206882348-5d5539a9-42f0-44a4-b3cf-d114436abc27.png)

I use pod anti affinity so all 3 pods will distribute to 3 EKS nodes (replica=3 in deployment file and min_replicas=3 in hpa files) to aviod single point of failure
![image](https://user-images.githubusercontent.com/36766101/206896200-5c1f751f-446e-46da-bd6a-d69553989af2.png)

![image](https://user-images.githubusercontent.com/36766101/206883514-7a2186fa-b592-4175-a7e2-5a76b5922861.png)


8 Some packages use helm to isntall to different namespaces
![image](https://user-images.githubusercontent.com/36766101/207176625-d496c25f-1b84-4986-a7ab-6f4fed266bbb.png)


