#!/bin/sh
svc_ip=`kubectl get svc  -n my-eks-app |grep Node |awk '{print $3}'`
i=0
while [ $i -ne 4 ]
do
        i=$(($i+1))
        nohup kubectl run -i --tty load-generator$i --rm --image=busybox:1.28 --restart=Never -- /bin/sh -c "while sleep 0.01; do wget -q -O- http://$svc_ip; done" -n my-eks-app  &
done
