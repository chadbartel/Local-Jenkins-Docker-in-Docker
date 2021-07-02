#!/bin/bash
export IMAGE_TAG=$(git rev-parse HEAD)
docker network create jenkins
docker volume create jenkins-docker-certs
docker volume create jenkins-data
docker run \
    --name jenkins-docker \
    --restart always \
    --detach \
    --privileged \
    --network jenkins \
    --network-alias docker \
    --env DOCKER_TLS_CERTDIR=/certs \
    --volume jenkins-docker-certs:/certs/client \
    --volume jenkins-data:/var/jenkins_home \
    --publish 2376:2376 \
    docker:dind \
    --storage-driver overlay2
docker build -t myjenkins-blueocean:$IMAGE_TAG .
docker run \
    --name jenkins-blueocean \
    --restart always \
    --detach \
    --network jenkins \
    --env DOCKER_HOST=tcp://docker:2376 \
    --env DOCKER_CERT_PATH=/cert/client \
    --env DOCKER_TLS_VERIFY=1 \
    --publish 8080:8080 \
    --publish 50000:50000 \
    --volume jenkins-data:/var/jenkins_home \
    --volume jenkins-docker-certs:/certs/client:ro \
    --volume /var/run/docker.sock:/var/run/docker.sock \
    myjenkins-blueocean:$IMAGE_TAG
sudo chown "$USER":"$USER" /home/"$USER"/.docker -R
sudo chmod g+rwx "$HOME/.docker" -R
sudo chmod 666 /var/run/docker.sock