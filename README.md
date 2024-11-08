 # eks-demo 

# Gitops introduction

![image](https://user-images.githubusercontent.com/36766101/207481346-6839f595-36d3-4420-baba-63ab96a1a825.png)

![image](https://user-images.githubusercontent.com/36766101/207506596-2064a66d-88d0-4df7-aab9-f36e06fa774d.png)


# Github action CI with Gitops CD

![image](https://github.com/user-attachments/assets/bea57bd9-acf6-44f3-a662-222bc0db1678)
The GitHub Action pipeline will build, tag, and then push the image of the source code into the private repository in Amazon ECR.
In the second and last article of this series, we will configure Argo CD (adding the app and the GitHub Repository to Argo CD, creating a secret in the Kubernetes cluster to connect Amazon ECR, etc.). After that, we will change the source code, push it to GitHub, and observe the results of this. The GitHub Action pipeline will be triggered automatically, and it will send the new image into the Amazon ECR. Then, Argo CD will automatically synchronize the Kubernetes cluster according to the changes in the yaml files, when it detects the changes in GitHub. Finally, we will observe the running of Argo CD by changing the number of Replicas in the Kubernetes manifest yaml file.

# Prerequisite 


0 I store terraform state file to workstation local filesystem, obviously it is only suitable for test/demo purpose. For any production environment, S3+Dynamodb or Terraform cloud is the desriable option.

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

5 for security reason, I set eks public access only by specific IP, please change my_company_public_ip to allow access to eks public endpoint 

6 run terraform init and terraform apply in backend directory after git clone from repo then return to the previous directory run terraform init and terraform apply



![image](https://user-images.githubusercontent.com/36766101/207231087-b65d0caa-6ce4-48e5-af3f-9430d173ab1f.png)


# Basic function description:
1 Totally 3 ALB will be created: 

First one is with SSL certificate as required by exposing the application publicly.This one also redirects http request to https.


![image](https://user-images.githubusercontent.com/36766101/206881975-1a11cc4a-a6b4-4248-b6aa-8f873a35525e.png)
![image](https://user-images.githubusercontent.com/36766101/206881984-44695d2d-07fe-4df1-b087-b5fa6229e5d3.png)

Second one is the ArgoCD admin console(ArgoCD console url is in the argoserver_url.txt and admin user password is in the argoserver_pwd.txt file where are generated by argocd.tf and get_argo_pwd.sh respectively)

The third one will be deployed when sync Argo CD repo and will demonstrate CI/CD pipeline/Gitops pipeline.

2 I added additional RDS access to the pod main.py with RDS access information stored in AWS SSM. 
Also added EFS to pod to simulate stateful workload. login to one pod and write to /data file which can be checked from another pod.

![image](https://user-images.githubusercontent.com/36766101/207304429-f80df0ac-5139-407a-a56a-85f5a16a9a5f.png)

![image](https://user-images.githubusercontent.com/36766101/207304641-085b45df-e097-43b2-af67-cdade39aa069.png)

![image](https://user-images.githubusercontent.com/36766101/207837371-8fc68536-7c64-4076-8f82-83c1ad7179aa.png)



3 I added WAF to protect the 1st ALB and one rule to the WAF so if one IP repeatedly accesses the ALB, will be blocked.
![image](https://user-images.githubusercontent.com/36766101/206881998-9ad65019-ddf5-4102-83c5-a3dac795fbe9.png)

![image](https://user-images.githubusercontent.com/36766101/208668437-d05a9f1c-298f-47e5-bdf2-44708ce9fb4d.png)


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

6 I add AWS App mesh (AWS version istio) and virtual router to send traffic (50% vs 50%) to backend virtual nodes to simulate blue/green deployment. 

![image](https://user-images.githubusercontent.com/36766101/209029918-3951cea2-ef06-48c3-a4ae-50c68d28da14.png)
![image](https://user-images.githubusercontent.com/36766101/209030001-39e9c495-f1b6-41a6-95f2-624d713882be.png)



7 Since the managed nodes are in ASG, more pods (triggered by hpa) deployed to namespaces will trigger EC2 instances added to ASG.


7 horizontal pod autoscaler installed to scale in/out pods according to the amount of traffic.Use the load-generate.sh to generate workload to scale out more pods.
![image](https://user-images.githubusercontent.com/36766101/206883527-692e87c2-b803-4de6-8364-87a4900c81e9.png)
We can use one scripe to generate work load which query the kubernetes service IP to cause horizon pod autoscale based on predefined cpu usage (set to 20% to quickly scale out more pods)
![image](https://user-images.githubusercontent.com/36766101/206883706-6ec2ce7b-9597-4af1-8f58-e394f989bbae.png)
![image](https://user-images.githubusercontent.com/36766101/206883795-cba29e66-6289-4cdb-bf9c-7205df6bee03.png)



pod use service account assume AWS IAM role to access AWS SSM parameter data
![image](https://user-images.githubusercontent.com/36766101/206882348-5d5539a9-42f0-44a4-b3cf-d114436abc27.png)







8 Some packages use helm to isntall to different namespaces
![image](https://user-images.githubusercontent.com/36766101/207176625-d496c25f-1b84-4986-a7ab-6f4fed266bbb.png)

9 To use IAM roles for service accounts in your cluster, you must create an IAM OIDC (OpenID Connect) Identity Provider.
OpenID Connect allows you to use JWTs to authenticate using third-party authentication services.

![image](https://user-images.githubusercontent.com/36766101/207186245-a625b5b1-997e-42e4-b8b3-73c063013a79.png)

10 Create 2 managed node group ,one is spot instance and another one is on demand instance.I use pod anti affinity so all 3 pods will distribute to 3 EKS nodes and pod to node affinity to run all 3 pods on spot nodes (replica=3 in deployment file and min_replicas=3 in hpa files) to aviod single point of failure 

![image](https://user-images.githubusercontent.com/36766101/207303963-136f9e1b-15ba-4d8b-8a69-d441bf0cb471.png)

spot instance will install  aws-node-termination-handler to graceful stop spot instance and avoid possible application interruption. 
![image](https://user-images.githubusercontent.com/36766101/209257913-28c42186-b2c4-486f-bf36-95f0eb72a992.png)

![image](https://user-images.githubusercontent.com/36766101/209257366-c816291b-0c4b-40da-a4b5-e109f2840f36.png)


11 cloudwatch loginsight can query pod log of specified namespace and key words, so gradually elimnate the requirements for ElasticSearch/Sumo Logic for log analysis. 
![image](https://user-images.githubusercontent.com/36766101/207839212-1a1da3fa-5946-48ae-aeed-e232cd78c67f.png)


# next step 

12 next step : EKS security https://aws.github.io/aws-eks-best-practices/security/docs/

12 next step : Kubescape for security (Kubescape tests whether a Kubernetes cluster is deployed securely 
according to multiple frameworks: regulatory, customized company policies, and 
DevSecOps best practices, such as the NSA/CISA and MITRE ATT&CK)  

curl -s https://raw.githubusercontent.com/armosec/kubescape/master/install.sh | /bin/bash 

kubescape list frameworks 
![image](https://user-images.githubusercontent.com/36766101/216764616-3fd553a3-8b34-4c4e-b036-a32f431afca0.png)

kubescape scan framework nsa --exclude-namespaces kube-system -v
![image](https://user-images.githubusercontent.com/36766101/216765038-f2f061d2-57b0-4b82-9ccb-9441a7239d39.png)

![image](https://user-images.githubusercontent.com/36766101/216764722-a9fa03c1-5f6f-48b4-8221-54539a723fd9.png)


13 next step: Backup and restore using Velero (It's always recommended to back up your production Kubernetes cluster resources.)

14 next step: Use Faclo to perform behavioral analytics

![image](https://user-images.githubusercontent.com/36766101/216871803-9c786bfb-5d08-4115-997d-a13eec5294e7.png)

15 next step: Chaos Engineering with AWS Fault Injection Simulator on an EKS cluster worker node

16 next step: Isolate the Pod by creating a Network Policy that denies all ingress and egress traffic to the pod
A deny all traffic rule may help stop an attack that is already underway by severing all connections to the pod. The following Network Policy will apply to a pod with the label app=web.

![image](https://user-images.githubusercontent.com/36766101/216926306-7b3f3eca-3d0e-4f3e-bb66-c81d2de241ba.png)

16 Container immutability can help make containerized applications more secure

kubectl get pod -n dev -o yaml web-frontend
Because runAsUser is set to 0, this Pod is running as the root user and cannot be considered immutable.

kubectl get pod -n dev -o yaml auth-rest
Because readOnlyRootFileSystem is set to true and allowPrivilegeEscalation is set to false, this Pod is immutable.

kubectl get pod -n dev -o yaml user-svc
Because readOnlyRootFileSystem and allowPrivilegeEscalation are both set to false, this Pod is not immutable.

17 kube-bench is a popular open source CIS Kubernetes Benchmark assessment tool created by AquaSecurity. kube-bench is a Go application that checks whether Kubernetes is deployed securely by running the checks documented in the CIS Kubernetes Benchmark. Tests are configured with YAML files, and this makes kube-bench easy to update as test specifications evolve. AquaSecurity is an AWS Advanced Technology Partner. https://github.com/aquasecurity/kube-bench/blob/main/docs/running.md#running-cis-benchmark-in-an-eks-cluster



15 next step: Karpenter automatically provisions new nodes in response to unschedulable pods. Karpenter does this by observing events within the Kubernetes cluster, and then sending commands to the underlying cloud provider
https://kubesandclouds.com/index.php/2022/01/04/karpenter-vs-cluster-autoscaler/
![image](https://github.com/xiongye77/eks-demo/assets/36766101/5957fec6-42ef-4e54-b698-3368e8c27ff6)
Karpenter configuration comes in the form of a Provisioner CRD (Custom Resource Definition). A single Karpenter Provisioner is capable of handling many different Pod shapes. Karpenter makes scheduling and provisioning decisions based on Pod attributes such as labels and affinity. A cluster may have more than one Provisioner, but for the moment we'll declare just one: the default Provisioner.
![image](https://github.com/xiongye77/eks-demo/assets/36766101/08bd8181-b1c5-4bd7-a795-1a15db1060d8)
https://www.eksworkshop.com/docs/autoscaling/compute/karpenter/

Karpenter configuration comes in the form of a NodePool CRD (Custom Resource Definition). A single Karpenter NodePool is capable of handling many different Pod shapes. Karpenter makes scheduling and provisioning decisions based on Pod attributes such as labels and affinity. A cluster may have more than one NodePool
![image](https://github.com/xiongye77/eks-demo/assets/36766101/88a4b5db-045f-433b-b807-dc09c14742c5)
![image](https://github.com/xiongye77/eks-demo/assets/36766101/80ae4fdb-eb37-4e20-9318-52cb1bcfed7d)
![image](https://github.com/xiongye77/eks-demo/assets/36766101/2c506d56-1f50-4813-9823-0789ddc9e858)
![image](https://github.com/xiongye77/eks-demo/assets/36766101/6b74ce6a-44ea-4527-91c3-8878f98a9e6d)
<img width="1200" alt="image" src="https://github.com/user-attachments/assets/2fc8b59a-fb49-48b8-b6ba-bd00801c9b43">
<img width="1231" alt="image" src="https://github.com/user-attachments/assets/ea2971ae-4409-49b4-a80d-866d07138274">
<img width="1718" alt="image" src="https://github.com/user-attachments/assets/b849aafe-369b-4be7-80e8-810277ef67a5">
<img width="702" alt="image" src="https://github.com/user-attachments/assets/cbec2563-f486-4146-9407-7b209040b46f">
<img width="661" alt="image" src="https://github.com/user-attachments/assets/8508f206-5139-4d9d-9bf9-a0a99c577e1c">


16 next step: Security groups for pods Security groups for pods integrate Amazon EC2 security groups with Kubernetes pods. You can use Amazon EC2 security groups to define rules that allow inbound and outbound network traffic to and from pods
https://docs.aws.amazon.com/eks/latest/userguide/security-groups-for-pods.html

17 next step:Securing cluster by using network policies.Use Project Calico to enforce Kubernetes network policies in cluster.https://www.tigera.io/project-calico/

18 next step: Installing or updating the Amazon VPC CNI plugin for Kubernetes metrics helper add-on  https://docs.aws.amazon.com/eks/latest/userguide/cni-metrics-helper.html

Amazon EKS implements cluster networking through the Amazon VPC Container Network Interface(VPC CNI) plugin. The CNI plugin allows Kubernetes Pods to have the same IP address as they do on the VPC network. 

19 next step: ExternalDNS with Amazon EKS ,ExternalDNS automates updating DNS records so that you can deploy a public facing application using just Kubernetes

20 next step: Kubernetes Operator. A Kubernetes Operator uses the Kubernetes API to create, configure, and manage instances of complex stateful applications on behalf of a Kubernetes user. There is a public repository called OperatorHub.io that is designed to be the public registry for finding Kubernetes Operator backend services. 


21 https://catalog.workshops.aws/eks-immersionday/en-US 


21 kubectl cp command to copy file from pod to/from local
kubectl cp <source-file-path> <destination-file-path>
kubectl cp /<path-to-your-file>/<file-name> <pod-name>:<fully-qualified-file-name> -c <container-name>
kubectl cp <pod-name>:<fully-qualified-file-name> /<path-to-your-file>/<file-name> -c <container-name>


![image](https://user-images.githubusercontent.com/36766101/216001994-78dfefb6-a6f7-4d4c-85e6-47f82374ae6a.png)


![image](https://user-images.githubusercontent.com/36766101/207834904-2561987b-3fd7-43b0-9ff1-18381e68031f.png)

![image](https://user-images.githubusercontent.com/36766101/207835719-847caaa4-8e36-40df-a1cf-4d80f23080da.png)

![image](https://user-images.githubusercontent.com/36766101/207835967-65781400-b0a4-4a0e-83a1-06d9d11c9593.png)

![image](https://user-images.githubusercontent.com/36766101/207836477-9b3730d8-ef7d-40c4-8763-2d589cc75c0b.png)


![image](https://user-images.githubusercontent.com/36766101/208350775-b9eda1d5-eefc-45ee-9076-3fc1f62db480.png)


![image](https://user-images.githubusercontent.com/36766101/208661683-c3b7848d-96b5-4253-8f59-41c0e99c1c35.png)

![image](https://user-images.githubusercontent.com/36766101/208826390-56a49f14-7712-4562-9317-7aa75784b278.png)


![image](https://user-images.githubusercontent.com/36766101/208662888-9821372b-f301-4a79-9b11-00d320ba53e3.png)

![image](https://user-images.githubusercontent.com/36766101/208664458-7d871617-acbb-4448-aa9e-eeb0df4f8d07.png)

![image](https://user-images.githubusercontent.com/36766101/208667128-8e5bd738-8c59-4e6e-bbbc-f4f9223dc9d7.png)

![image](https://user-images.githubusercontent.com/36766101/208826718-6a370ea5-d06a-4019-a97d-c718bf71361e.png)
![image](https://user-images.githubusercontent.com/36766101/208827060-ad4f2eb3-ec36-44b2-8fa0-a7623c1dcadd.png)


![image](https://user-images.githubusercontent.com/36766101/208667562-a8017788-2bcf-4569-b781-a55e1d1eac06.png)
![image](https://user-images.githubusercontent.com/36766101/208667857-10d122bb-a128-4c4f-8709-cd9e4acdc1c2.png)
![image](https://user-images.githubusercontent.com/36766101/208668651-e9ffd55a-049b-4cca-bedc-8612af0c2c6f.png)

![image](https://user-images.githubusercontent.com/36766101/208814456-7a934ec2-9514-466c-9538-9da35715c90e.png)


![image](https://user-images.githubusercontent.com/36766101/216764970-1a6bcc72-3aa6-40ad-bd5e-80f91d6b79a4.png)


Use RBCA to control access to Secret 
![image](https://user-images.githubusercontent.com/36766101/215916024-079fbb97-1050-4f31-901d-fee24cc464c0.png)


# Gives Access to our IAM Roles to EKS Cluster
In order to give access to the IAM Roles we defined previously to our EKS cluster, we need to add specific mapRoles to the aws-auth ConfigMap

The Advantage of using Role to access the cluster instead of specifying directly IAM users is that it will be easier to manage: we won’t have to update the ConfigMap each time we want to add or remove users, we will just need to add or remove users from the IAM Group and we just configure the ConfigMap to allow the IAM Role associated to the IAM Group.

# Enabling IAM Roles for Service Accounts on your Cluster

In Amazon EKS 1.23, we will be changing the default runtime from Docker to containerd. This means 1.22 will be the last release with Docker container runtime support. It is recommended that you test your workloads using containerd during the 1.21 lifecycle so you can make sure you don’t depend on any Docker specific features such as mounting the Docker socket or using docker-in-docker for container builds.

To most simple word, container runtime is software that runs containers
![image](https://user-images.githubusercontent.com/36766101/216730756-5056458a-d57b-4b84-b9ca-03e64eaa356b.png)
![image](https://user-images.githubusercontent.com/36766101/216730822-f1871b9a-714e-4caa-bfbc-2444a142bab4.png)


# AWS backup to copy Dynamodb back to another account and another region (2023/03/01)

![image](https://user-images.githubusercontent.com/36766101/222131815-87de8018-192d-46af-97f7-3b2cfd589c40.png)
![image](https://user-images.githubusercontent.com/36766101/222131855-b168ba07-d10b-4b9d-bba7-8a0c31a35492.png)
![image](https://user-images.githubusercontent.com/36766101/222136960-a8fddf90-ab6b-4071-bff9-5945256ecd5a.png)

# AWS Dynamodb backup to another account/region S3 bucket and import 
![image](https://user-images.githubusercontent.com/36766101/222132735-b7a4ce40-04b1-4116-baef-fdb666267d0e.png)

# Lesson learned while scaling Kubernetes cluster to 1000 pods in AWS EKS
# VPC should have a sufficient free IP address pool 
Make sure the VPC where you deploy your pods should have sufficient IP blocks. For deploying 1000 pods, you at least start with /21 CIDR blocks (or depending upon your requirement)so that you have at least 1000 free IP addresses, also take into account future growth.

# AWS Quota limit 
For the All Standard (A, C, D, H, I, M, R, T, Z) Spot Instance Requests there is a quota limit set to 96 instances which may or may not be enough for this use case

# Run one EKS cluster per VPC
AWS recommends one EKS cluster per VPC so that Kubernetes will be the only consumer of IP address within the VPC.

# Use of bottlerocket OS vs Amazon Linux EKS optimized AMI
Bottlerocket is an open-source operating system that’s purpose built for running containers. Many general operating systems have the vast majority of software they never need, contributing to the additional overhead on the nodes. 

# Use of Karpenter as cluster auto-scaler: 
One of the biggest advantages of using Karpenter vs. Cluster AutoScaler is Karpenter directly calls the EC2 API to launch or remove nodes as well as dynamically chooses the best EC2 instance types(as shown in the code below)or computes resources for the workload, whereas in case Cluster AutoScaler working on AutoScaling group that needs to homogenous, i.e., all the servers need to be of the same configuration(same CPU and RAM).Use of Karpenter as cluster auto-scaler: One of the biggest advantages of using Karpenter vs. Cluster AutoScaler is Karpenter directly calls the EC2 API to launch or remove nodes as well as dynamically chooses the best EC2 instance types(as shown in the code below)or computes resources for the workload, whereas in case Cluster AutoScaler working on AutoScaling group that needs to homogenous, i.e., all the servers need to be of the same configuration(same CPU and RAM).

# Choose instance type for worker node: 
Choose the instance type for the worker node: You need to choose the instance type where you run your workload. Here you will see the advantage of using Karpenter, which automatically chooses the instance type which doesn’t need to be homogenous.

# CloudWatch Container Insight: 
Use of container insight for centralized logging and metrics: To figure out what’s going on in your application pods, we need an agent that forward all the logs and metrics to a centralized location for easy searching and analysis.CloudWatch Container Insights provides a single pane to view all the metrics and logs.

# EKS Security and Networking
![image](https://github.com/xiongye77/eks-demo/assets/36766101/4e4ffe06-19aa-4929-bfc4-e9d14b4dfe2a)


# Kubernetes Event-driven Autoscaling
![image](https://github.com/xiongye77/eks-demo/assets/36766101/9f88b493-9fbf-4531-a178-1f43e613d5c5)
![image](https://github.com/xiongye77/eks-demo/assets/36766101/15f4fb25-72f1-4574-96f8-f33f01b80821)
![image](https://github.com/xiongye77/eks-demo/assets/36766101/26e6e444-3eb0-42f3-a3fb-2089f9d31d25)
![image](https://github.com/xiongye77/eks-demo/assets/36766101/ea8df0af-3370-425c-a7aa-7c3870c370b4)
![image](https://github.com/xiongye77/eks-demo/assets/36766101/793a228c-52f9-4111-9e88-2cdd278b9a39)
![image](https://github.com/xiongye77/eks-demo/assets/36766101/fd85d90b-037f-49cc-92fc-9077db202b03)
![image](https://github.com/xiongye77/eks-demo/assets/36766101/118c7887-7a2a-4516-bb45-431e7d2c3ec9)
![image](https://github.com/xiongye77/eks-demo/assets/36766101/21ecb58c-eb63-409f-a656-d638e49308be)




# Setting up right resource limits: 
Once you are done with scalability testing and come up with optimal configuration, setting up the resource limit is critical. You don’t want to set the resource limit too low, as Kubernetes will schedule more pods on worker nodes with a low limit. Now, if these pods get busy simultaneously, there won’t be enough resources for each pod to hit its CPU limits. This will lead to contention and performance degradation in your application.




![image](https://github.com/xiongye77/eks-demo/assets/36766101/4ce025ce-b19c-4f15-a95e-1ec8ad135787)


# EKS Node Viewer (2024/04/17) 
https://github.com/awslabs/eks-node-viewer
EKS Node Viewer is a simple but powerful tool that can be used to improve the efficiency and performance of Kubernetes clusters. It is easy to use and install, and it provides a clear and concise view of node usage. It does not look at the actual pod resource usage.
![image](https://github.com/xiongye77/eks-demo/assets/36766101/45871417-6ae2-4995-a5d4-9d25b64ebcf2)

# EKS Observability
Observability is a foundational element of a well-architected EKS environment. AWS provides native (CloudWatch) and open source managed (Amazon Managed Service for Prometheus)solutions for monitoring, logging, alarming, and dashboarding of EKS environments.

# Kubernetes logging 
Kubernetes logging  can be divided into control plane logging, node logging, and application logging. 

# Control Plane logging 
The Kubernetes control plane is a set of components that manage Kubernetes clusters and produce logs used for auditing and diagnostic purposes. With Amazon EKS, you can turn on logs for different control plane components and send them to Amazon CloudWatch.
![image](https://github.com/xiongye77/eks-demo/assets/36766101/63162409-5d9e-4dd6-9cc6-eed82103f77f)


aws eks update-cluster-config \
    --region $AWS_REGION \
    --name $EKS_CLUSTER_NAME \
    --logging '{"clusterLogging":[{"types":["api","audit","authenticator","controllerManager","scheduler"],"enabled":true}]}'
sleep 30
aws eks wait cluster-active --name $EKS_CLUSTER_NAME

![image](https://github.com/xiongye77/eks-demo/assets/36766101/4842197b-dbd7-48b8-8f5b-1332c3689d8c)

![image](https://github.com/xiongye77/eks-demo/assets/36766101/26daeef2-fdca-439b-84b5-429cb5e735cb)
![image](https://github.com/xiongye77/eks-demo/assets/36766101/6a20bcdf-02c4-4f3b-9ef8-70d5bdd2820d)

# Pod logging
In Kubernetes, container logs are written to /var/log/pods/*.log on the node. Kubelet and container runtime write their own logs to /var/logs or to journald, in operating systems with systemd. Then cluster-wide log collector systems like Fluentd can tail these log files on the node and ship logs for retention. These log collector systems usually run as DaemonSets on worker nodes.
AWS provides a Fluent Bit image with plugins for both CloudWatch Logs and Kinesis Data Firehose. The AWS for Fluent Bit image is available on the Amazon ECR Public Gallery.(https://gallery.ecr.aws/aws-observability/aws-for-fluent-bit)
https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Container-Insights-setup-logs-FluentBit.html#Container-Insights-FluentBit-setup

# Observability with OpenSearch
https://github.com/aws-samples/eks-workshop-v2/blob/stable/manifests/modules/observability/opensearch/.workshop/terraform/preprovision/main.tf
# EKS DR
![image](https://github.com/xiongye77/eks-demo/assets/36766101/ef2be347-1124-4934-a456-742719070af4)




#  kubectl config get-contexts/kubectl config current-context/kubectl config view/kubectl cluster-info --context /kubectl config get-clusters/kubectl get gitrepo -n namespace/kubectl get helmrelease
![image](https://github.com/xiongye77/eks-demo/assets/36766101/1eaf94b4-de49-4bce-9662-91a494bc357d)
![image](https://github.com/xiongye77/eks-demo/assets/36766101/057ca6a6-3ec9-4240-95b1-3add484e9bd4)

# Kustomize is a standalone tool to customize Kubernetes objects through a kustomization file.




# Securing Kubernetes Secrets: Integrating AWS Secrets Manager with EKS
![image](https://github.com/xiongye77/eks-demo/assets/36766101/30926670-ab96-449a-af79-debe89e76dc4)

Step 1. Install the Secrets Store CSI Driver and AWS Secrets and Configuration Provider
helm repo add secrets-store-csi-driver https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts
helm repo add aws-secrets-manager https://aws.github.io/secrets-store-csi-driver-provider-aws
helm install -n kube-system csi-secrets-store secrets-store-csi-driver/secrets-store-csi-driver
helm install -n kube-system secrets-provider-aws aws-secrets-manager/secrets-store-csi-driver-provider-aws
![image](https://github.com/xiongye77/eks-demo/assets/36766101/26db24eb-8508-440a-8d95-c2b57c582ac1)


Step 2 Create AWS Secret Manager secret and create iam role can access the secret and create kubernetes service account, let pod use that service account 

Step 3 Create SecretProviderClass 
![image](https://github.com/xiongye77/eks-demo/assets/36766101/9ab1718a-d003-4502-88fb-469b8ce7f26e)

Step 4 mount the secret manager as volume to container, please refer 
https://github.com/xiongye77/eks-demo/blob/main/SecretProviderClass.yaml


# GuardDuty for EKS

we'll enable Amazon GuardDuty EKS Protection. This will provide threat detection coverage for EKS Audit Log Monitoring and EKS Runtime Monitoring to help you protect your clusters.

EKS Audit Log Monitoring uses Kubernetes audit logs to capture chronological activities from users, applications using the Kubernetes API, and the control plane searching for potentially suspicious activities.

EKS Runtime Monitoring uses operating system-level events to help you detect potential threats in Amazon EKS nodes and containers.


aws guardduty create-detector --enable --features '[{"Name" : "EKS_AUDIT_LOGS", "Status" : "ENABLED"}, {"Name" : "EKS_RUNTIME_MONITORING", "Status" : "ENABLED", "AdditionalConfiguration" : [{"Name" : "EKS_ADDON_MANAGEMENT", "Status" : "ENABLED"}]}]'




![image](https://github.com/xiongye77/eks-demo/assets/36766101/ec14bcdf-6790-4b4a-acc8-ef1bd5b79f05)
EKS Audit Log Monitoring when enabled, immediately begins to monitor Kubernetes audit logs from your clusters and analyze them to detect potentially malicious and suspicious activity. It consumes Kubernetes audit log events directly from the Amazon EKS control plane logging feature through an independent stream of flow logs.


![image](https://github.com/xiongye77/eks-demo/assets/36766101/8c914f41-4977-4d24-98fb-d42af7efd7db)
Make sure GuardDuty pod running on EKS nodes
![image](https://github.com/xiongye77/eks-demo/assets/36766101/5ae6f911-43f0-4518-ace6-7088e1ee935c)
step 1  run a Pod in the kube-system Namespace that provides access to its shell environment.
step 2  run "kubectl -n kube-system exec nginx -- pwd"  generate the Execution:Kubernetes/ExecInKubeSystemPod finding 
![image](https://github.com/xiongye77/eks-demo/assets/36766101/2c8237a1-3743-47ca-a51e-af16ae8c115c)


# Kubernetes PDB
In Kubernetes, there are different ways to ensure your application is always available. You can set, for example, the right pod resources, autoscaling to make sure your application can keep up with demand and doesn't crash, health checks to restart failing containers or remove them from service and increasing replica count for redundancy.  These are ways to manage disruptions. 

One common disruption that happens all the time is during a deployment. During a deployment, we make sure there is a smooth transition to the new version of your application. You do this by setting a proper deployment strategy such as RollingUpdate. Disruptions can be categorised into two types - voluntary and involuntary disruptions

Pod disruption budgets
Pod disruption budget (pdb for short) is a Kubernetes resource object that limits the number of Pods of a replicated application that are down simultaneously from voluntary disruptions. For example, say you have an application with multiple replicas and with a pdb set to maxUnavailable: 1, the pdb will only allow one pod to be evicted or down one at a time. This means for example during a node scale down, it will wait for the evicted pod to get rescheduled and run before another pod is evicted or taken down. 

The pdb will also protect the application in cases where rescheduled new pods didn’t come up healthy for some reasons. The pdb will prevent the eviction of the other healthy pods until the new pod is fixed or becomes healthy.

![image](https://github.com/xiongye77/eks-demo/assets/36766101/23bec286-e5b9-4fae-aad6-4712e3aa3035)


# Deployment 
Rollback to specific version 
kubectl rollout undo deployment/application-deployment --to-revision=3
![image](https://github.com/xiongye77/eks-demo/assets/36766101/984bf641-34d9-4476-865b-8a810c116300)



# AWS VPC Lattice 
![image](https://github.com/xiongye77/eks-demo/assets/36766101/cbc08beb-56b8-42c1-ba28-5d6054650b27)
![image](https://github.com/xiongye77/eks-demo/assets/36766101/8747103e-37f2-45dc-88ac-2c380f10d747)
![image](https://github.com/xiongye77/eks-demo/assets/36766101/97e0de63-dd98-40ec-bb3c-8aebff564926)




![image](https://github.com/xiongye77/eks-demo/assets/36766101/b70af46a-9db1-4500-aaef-1d5101bbd7a2)
![image](https://github.com/xiongye77/eks-demo/assets/36766101/5a3725da-3391-4bd2-85c4-0066ce7c9a69)
![image](https://github.com/xiongye77/eks-demo/assets/36766101/e1018a67-9d0e-40bd-8a02-fdf6c640cc0c)
![image](https://github.com/xiongye77/eks-demo/assets/36766101/db428e39-3b9b-45bc-9b7e-bbc855471688)
![image](https://github.com/xiongye77/eks-demo/assets/36766101/dd76f0e9-cff5-4c49-9de5-f13ada8fc2c8)
![image](https://github.com/xiongye77/eks-demo/assets/36766101/d2205e1c-08d9-47fb-8ee1-68761e85422f)
![image](https://github.com/xiongye77/eks-demo/assets/36766101/d370cd77-1f68-4ea5-b008-83023b3ccdd5)
![image](https://github.com/xiongye77/eks-demo/assets/36766101/52ed8147-e6e3-4419-8098-e670a70da847)



# EKS cluster endpoint public or private 
When you create a new cluster, Amazon EKS creates an endpoint for the managed Kubernetes API server that you use to communicate with your cluster (using Kubernetes management tools such as kubectl). By default, this API server endpoint is public to the internet, and access to the API server is secured using a combination of AWS Identity and Access Management (IAM) and native Kubernetes Role Based Access Control (RBAC).
![image](https://github.com/xiongye77/eks-demo/assets/36766101/baca99f4-b2dc-429a-9abe-7a95c3285bae)
![image](https://github.com/xiongye77/eks-demo/assets/36766101/1b784dc2-b342-4096-b83e-960ed6615b56)



# Identity Provider type

OpenID Connect is more suited for modern applications, especially those requiring both authentication and authorization through simple, JSON-based protocols.
SAML is better suited for enterprise environments where XML-based protocols are used for SSO and user authentication in a more traditional setup.
![image](https://github.com/xiongye77/eks-demo/assets/36766101/f575e519-02ca-40b6-aaa9-638f28374d59)


![image](https://github.com/xiongye77/eks-demo/assets/36766101/f8a9d941-fa9e-41d9-a039-954e5187f707)
