# init a base image (Alpine is small Linux distro)
FROM python:3.6.1-alpine
# define the present working directory
WORKDIR /datenworkes-gabriel
# copy the contents into the working dir
ADD . /datenworkes-gabriel
#
#RUN pip freeze > requirements.txt
# run pip to install the dependencies of the flask app
RUN python3 -m pip install -r requirements.txt
#RUN pip install --no-cache-dir -r requirements.txt  <- old
# define the command to start the container
CMD ["python","app.py"]