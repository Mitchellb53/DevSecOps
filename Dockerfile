A docker file is a list of instructions used to help build an image from the docker cli 

Details of a docker file contain : 
FROM	Creates a layer from Docker Image. Specifies the base image to use
COPY	Copies the files from the local directory to the docker image on a specific location
ADD	Similar to COPY but supports file download (HTTP), auto extracting compressed file(s), and replacing the existing file to a specific location if needed forcefully
RUN	Run OS command (just like you would do on a terminal) but only executes it during the image creation process
ENTRYPOINT	Run a command as the default command when the container starts. Its the entrypoint to the utility/command
CMD	Command to run when a container starts or arguments to ENTRYPOINT if specified

We will try to build a Docker image with Ubuntu 18.04 as the base image. We will also install a web server in it.

Create a new file called Dockerfile under learn-dockerfile directory.

mkdir learn-dockerfile

cd learn-dockerfile

touch Dockerfile

cat > Dockerfile <<EOL
FROM ubuntu:18.04

RUN apt install nginx
EOL

As mentioned before, we run the OS command(s) available in Dockerfile to install the Nginx server. Let’s try to build the image.
docker build -t nginx-custom .

nteresting, why the image build process failed? Because we didn’t do apt update before installing the package. Hence the error E: Unable to locate package nginx.

Let’s try to update our Dockerfile.

cat > Dockerfile <<EOL
FROM ubuntu:18.04

RUN apt update && apt install nginx
EOL

Rebuild image 
docker build -t nginx-custom .

Error occured on line 13 as a yes/no prompt was encountered 

This can be fixed by running the -y option when installing nginx. 

Edit the dockerfile again using the -y option 

cat > Dockerfile <<EOL
FROM ubuntu:18.04

RUN apt update && apt install -y nginx
EOL

Then build again 
docker build -t nginx-custom .

and there is no problem with the built image 


In the previous step, we have learned the basic syntax of Dockerfile. Sometimes, it’s faster to create a container using an image as a base and add extra layers on top using the RUN commands. Once we are happy with the results, we can create a Dockerfile.

Let’s create a container using the ubuntu:18.04 image.

docker run -d --name ubuntu -it ubuntu:18.04

Use the docker exec command to start the Bash process inside the container (imagine it as though you are logging into a container).

docker exec -it ubuntu bash

Update the cache 
apt update

Then install nginx package 
apt install -y nginx

OK, we installed the nginx webserver. We would want to start the nginx service, but how should we do that?

service nginx start

Great, our web server is running. We can verify it by requesting a webpage from our local container using the curl command.

curl localhost

Oops, looks like curl is not installed. Let’s install curl utility with the apt install command.

apt install curl -y

Then, run the previous command once again, and you will see the following message.
curl localhost

The above file is our previous Dockerfile. Do you think we can just add service nginx start into the Dockerfile?

Yes, we can do it. However, our custom image still won’t start the service. The reason being, we didn’t put the command in either CMD or ENTRYPOINT instructions.

As mentioned before, CMD/ENTRYPOINT instruction will execute the command at the end of the container start process.


exit

Let’s update our previous Dockerfile with CMD command.

cat > Dockerfile <<EOL
FROM ubuntu:18.04

RUN apt update && apt install nginx -y

CMD ["/bin/bash", "-c" , "service nginx start"]
EOL

docker build -t custom-nginx .

Run the image as a container.

docker run -d -it --name custom-nginx-container custom-nginx

Let’s see what containers are running on our machine.

docker ps -a

As you can see, our container has Exited. We can see the logs to ascertain what went wrong using the docker logs command.

docker logs custom-nginx-container

An easy fix is to add sleep after the service command using CMD instruction.

If everything goes well, our container should run without issuing the Exited status.

Edit Dockerfile with your favorite text editor like vim/nano and paste the following code in your Dockerfile.

cat > Dockerfile <<EOL
FROM ubuntu:18.04

RUN apt update && apt install nginx -y

CMD ["/bin/bash", "-c" , "service nginx start"]
CMD [";sleep infinity"]
EOL
Let’s re-build the image and run the image.

docker build -t custom-nginx .

Remove the old container and run the image as a container again.

docker rm -f custom-nginx-container

docker run -d -it --name custom-nginx-container custom-nginx

We’re trying to add another CMD instruction to execute the command; however, we got another error now

It seems only the last cmd was invoked. If more than one CMD instruction is specified, only the last CMD instruction is considered, so let’s move our sleep command on the same CMD line.

cat > Dockerfile <<EOL
FROM ubuntu:18.04

RUN apt update && apt install nginx -y

CMD ["/bin/bash", "-c" , "service nginx start; sleep infinity"]
EOL
Re-build the image, then run the image. It should work fine now.
docker build -t custom-nginx .

docker rm -f custom-nginx-container

docker run -d -it --name custom-nginx-container custom-nginx

docker ps -a

sleep infinity tells the container to keep the process alive. It’s crude, but it gets the job done. There are several other approaches to keep our container process alive, and we have picked the easiest of them all.

Now, let’s explore the difference between CMD and ENTRYPOINT.

cat > Dockerfile <<EOL
FROM ubuntu:18.04

RUN apt update && apt install nginx -y

ENTRYPOINT ["/bin/bash", "-c"]

CMD ["service nginx start; sleep infinity"]
EOL
With ENTRYPOINT, we set the image’s default command when running a container. What does it mean?

Please have a look at the CMD instruction in the above Dockerfile. The instruction is executing a service command followed by the sleep command. What would happen if we remove sleep infinity command in CMD?

Let’s remove sleep infinity from the CMD instruction altogether to see ENTRYPOINT’s affect on the container.

cat > Dockerfile <<EOL
FROM ubuntu:18.04

RUN apt update && apt install nginx -y

ENTRYPOINT ["/bin/bash", "-c"]

CMD ["service nginx start"]
EOL
Re-build the image and run the image with the following command.

docker build -t custom-nginx .

docker rm -f custom-nginx-container

docker run -d -it --name custom-nginx-container custom-nginx

docker ps

Analyze why the container is not alive?

Please have a look at docker logs command, the CMD instruction is successfully run or completed the job but, since there is no other process that keeps the container alive it causes the container to exit.

Run the same image using a different name (remember --name option?) with a bash towards the end.

docker run -d --name nginx-one -it custom-nginx bash

docker ps

The second container is alive. Why?
We override the CMD instruction to run bash shell instead of service nginx start to interact with the container. The CMD is overridden from the Docker Command Line Interface (CLI) when running the container using docker run command.
