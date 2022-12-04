import boto3 
import socket
import psycopg2

from flask import Flask 
 
app = Flask(__name__) 
ssm = boto3.client('ssm','us-east-1') 
 
@app.route("/") 
def hello(): 
    parameter = ssm.get_parameter(Name='interview-parameter', WithDecryption=True) 
    db_url_parameter =  ssm.get_parameter(Name='rds-endpoint')
    password_parameter = ssm.get_parameter(Name='rds-password', WithDecryption=True)
    conn_string = "host= {0} dbname='kubernetesdb' user='postgres' password={1}".format(db_url_parameter['Parameter']['Value'],password_parameter['Parameter']['Value'])
    conn = psycopg2.connect(conn_string)
    cursor = conn.cursor()
    cursor.execute("SELECT version();")
    version = cursor.fetchone()

    conn.close()
    return "You have reached pod {0}. This pod read the SSM parameter value of: {1} rds version is  {2}".format(socket.gethostname(), parameter['Parameter']['Value'], version) 
 
if __name__ == "__main__": 
    app.run(host='0.0.0.0', port=8080)
