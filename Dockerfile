FROM python:3.9 
 
RUN mkdir /app 
WORKDIR /app 
ADD ./requirements.txt /app/ 
RUN pip install -r requirements.txt 
ADD ./main.py /app/ 
 
EXPOSE 8080 
CMD ["python", "/app/main.py"]
