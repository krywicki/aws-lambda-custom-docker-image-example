# aws-lambda-custom-docker-image-example

## Overview

This is an example of a custom base Docker image for AWS Lambda. It uses ```python:3.8-buster``` as a base image.
It echos back any ```json``` input and converts ```audio/sample.mp3``` to ```audio/sample.wav``` via ```ffmpeg```.

## Setup

* Requirements
    * docker
    * docker-compose

Perform the following steps to run the project:

* Start lambda container locally in a terminal
    ```bash
    docker-compose up
    ```

* In a separate terminal, perform a ```curl``` request on the lambda container
    ```bash
    curl -XPOST "http://localhost:9000/2015-03-31/functions/function/invocations" -d '{ "hello": "world" }'
    ```

* Confirm Results
    * Observe that the ```curl``` request has returned
        ```bash
        {"Hello": "World"}
        ```

    * Observe that ```audio/sample.wav``` now exists


## Custom AWS Lambda Images
---

A Lambda Dockerimage with a custom base image requires several things to work as an AWS Lambda.

* Lambda Runtime Interface Client (RIC)
* (Optional) Runtime Interface Emulator (RIE)
* Lambda Code

### Lambda Runtime Interface Client

This is a client that manages the interaction between Lambda and your function code.

It is a smart idea a separate build layer in your Dockerfile for building the RIC, as seen below

*Dockerfile Snippet*
```Dockerfile
# Define function directory
ARG FUNCTION_DIR="/function"

##################################################
# Use Temporary Build Image to Build lamabdaric
##################################################

FROM python:3.8-buster as build-image

# Install aws-lambda-cpp build dependencies
RUN apt-get update && \
  apt-get install -y \
  g++ \
  make \
  cmake \
  unzip \
  libcurl4-openssl-dev

# Include global arg in this stage of the build
ARG FUNCTION_DIR
# Create function directory
RUN mkdir -p ${FUNCTION_DIR}

# Copy function code
COPY src ${FUNCTION_DIR}

# Install the runtime interface client
RUN pip install \
        --target ${FUNCTION_DIR} \
        awslambdaric
```

### Runtime Interface Emulator

The Lambda Runtime Interface Emulator is a proxy for Lambda's Runtime and Extensions APIs, which allows
developers to locally test their Lambda function packaged as a container image. It's a lightweight web-server
that converts HTTP requests to JSON events and maintains functional parity with Lambda Runtime API in the cloud.

It is recommened to invoke RIE from a script that can determine if the lambda is executing locally or in the cloud.

This project keeps the RIE executables in the ```lambda_runtime``` directory.

*Script Example*

```sh
#!/bin/sh

if [ -z "${AWS_LAMBDA_RUNTIME_API}" ]; then
  exec aws-lambda-rie /usr/local/bin/python -m awslambdaric $@
else
  exec /usr/local/bin/python -m awslambdaric $@
fi
```

The entrypoint for the Lambda Dockerfile should be the script so that a Lambda Container can be dynamically run locally
or in the cloud with difficulty.

*Dockerfile Snippet*
```Dockerfile
ENTRYPOINT [ "/runtime.sh" ]
CMD [ "lambda_handler.lambda_handler" ]
```

### Lambda Code

This is just a normal copy of code via ```Dockerfile COPY``` command.

*Dockerfile Snippet*
```Dockerfile
# Copy function code
ARG FUNCTION_DIR="/function"
COPY src ${FUNCTION_DIR}
```
