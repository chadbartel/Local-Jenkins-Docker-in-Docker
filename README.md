# Local-Jenkins-Docker-in-Docker

My local Jenkins server using docker:dind and Blue Ocean.

This guide follows the steps as described [here](https://www.jenkins.io/doc/book/installing/docker/#on-macos-and-linux).

1. Create a bridge network:

    ```bash
        docker network create jenkins
    ```

2. Create a volume for Jenkins data and Jenkins cert data:

    ```bash
        docker volume create jenkins-docker-certs
        docker volume create jenkins-data
    ```

3. Download and run the `docker:dind` Docker image to execute Docker commands inside Jenkins nodes:

    ```bash
        docker run \
            --name jenkins-docker \
            --rm \
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
    ```

4. Create a custom Jenkins Docker image using the configuation below and then build the image:

    * `Dockerfile`:

        ```dockerfile
            FROM jenkins/jenkins:2.289.1-lts-jdk11

            USER root
            RUN apt-get update && \
                apt-get install upgrade -y && \
                apt-get install -y \
                    apt-transport-https \
                    ca-certificates \
                    curl \
                    gnupg2 \
                    software-properties-common
            RUN curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
            RUN apt-key fingerprint 0EBFCD88
            RUN add-apt-repository \
                "deb [arch=amd64] https://download.docker.com/linux/debian \
                $(lsb_release -cs) stable"
            RUN apt-get update && \
                apt-get install -y docker-ce-cli

            USER jenkins
            RUN jenkins-plugin-cli \
                --plugins "blueocean:1.24.6 docker-workflow:1.26"
        ```

    * Build the image:

        ```bash
            docker build -t myjenkins-blueocean:$(git rev-parse HEAD) .
        ```

5. Run the custom Jenkins Docker image as follows:

    ```bash
        docker run \
            --name jenkins-blueocean \
            --rm \
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
            myjenkins-blueocean:$(git rev-parse HEAD)
    ```

6. Open `http://localhost:8080` in your browser.

7. Retrieve the admin password either option below:

    * In the server CLI:

        ```bash
            sudo cat /var/lib/jenkins/secrets/initialAdminPassword
        ```

    * Running Jenkins in Docker:

        ```bash
            sudo docker exec ${CONTAINER_ID or CONTAINER_NAME} cat /var/jenkins_home/secrets/initialAdminPassword
        ```
