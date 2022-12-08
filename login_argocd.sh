argocd_url=`cat argoserver_url.txt`
argocd_pwd=`cat argoserver_pwd.txt`
argocd login $argocd_url  --username admin --password $argocd_pwd  --insecure
echo "Login to ArgoCD server"

CONTEXT_NAME=`kubectl config view -o jsonpath='{.contexts[].name}'`
argocd cluster add --yes  $CONTEXT_NAME
echo "Add K8S cluster to ArgoCD"
k8s_cluster=`argocd cluster list |grep eks |awk '{print $1}'`
echo $k8s_cluster
kubectl create namespace gitops-demo
argocd app create gitops-demo --repo https://github.com/xiongye77/eks-gitops-demo.git --path ./ --dest-server $k8s_cluster --dest-namespace gitops-demo
argocd app list
echo "ArgoCD application list"

