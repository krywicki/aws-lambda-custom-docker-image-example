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

#####################################################################################
# Create Final Lambda Image
#
# * COPY Built lambdaric from buildimage
# * COPY RIE (Runtime Interface Emulator) for running docker container locally
# * COPY lambda src code
# * SET entry point into lambda container (via runtime.sh script)
#####################################################################################

# Multi-stage build: grab a fresh copy of the base image
FROM python:3.8-buster

# Include global arg in this stage of the build
ARG FUNCTION_DIR
# Set working directory to function root directory
WORKDIR ${FUNCTION_DIR}

# Install Runtime Interface Emulator (for local running)
COPY lambda_runtime/runtime.sh /runtime.sh
RUN curl \
  -s -L "https://github.com/aws/aws-lambda-runtime-interface-emulator/releases/download/1.1/aws-lambda-rie" \
  -o /usr/local/bin/aws-lambda-rie
RUN chmod +x /runtime.sh /usr/local/bin/aws-lambda-rie

# Copy in the build image dependencies
COPY --from=build-image ${FUNCTION_DIR} ${FUNCTION_DIR}

# Install
RUN apt update && \
    apt install -y ffmpeg && \
    pip install -r requirements.txt

ENTRYPOINT [ "/runtime.sh" ]
CMD [ "lambda_handler.lambda_handler" ]
