"""
Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
"""
kubectl get resourcequota -n dna-airflow


"""
 
 
from airflow import DAG
from datetime import datetime
from airflow.providers.cncf.kubernetes.operators.kubernetes_pod import KubernetesPodOperator
from kubernetes.client import models as k8s_models


default_args = {
   'owner': 'aws',
   'depends_on_past': False,
   'start_date': datetime(2019, 2, 20),
   'provide_context': True
}

dag = DAG(
   'kubernetes_pod_awscli', default_args=default_args, schedule_interval=None)

#use a kube_config stored in s3 dags folder for now
kube_config_path = '/usr/local/airflow/dags/kube_config.yaml'

podRun = KubernetesPodOperator(
                       namespace="dna-airflow",
                       image="328916801733.dkr.ecr.ap-southeast-2.amazonaws.com/nginx:latest",
                       cmds=["ls"],                
                       labels={"foo": "bar"},
                       name="mwaa-pod-awscli",
                       task_id="pod-task",
                       get_logs=True,
                       dag=dag,
                       container_resources=k8s_models.V1ResourceRequirements(
                           requests={"cpu": "1000m", "memory": "1G"},
                           limits={"cpu": "4000m", "memory": "4G"}
                       ),
                       is_delete_operator_pod=False,
                       service_account_name='dna-airflow-iam-role',
                       config_file=kube_config_path,
                       in_cluster=False,
                       cluster_context='ap-southeast-2.k8s-paas-test-rua/dna-airflow'
                       )
