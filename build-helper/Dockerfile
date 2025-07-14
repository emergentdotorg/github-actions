# Set the base image to use for subsequent instructions
FROM alpine:3.22

RUN apk add --no-cache bash

ARG SRC_DIR=/usr/src
ENV SRC_DIR=$SRC_DIR

# Copy any source file(s) required for the action
COPY src/* ${SRC_DIR}/

# Set the working directory inside the container
WORKDIR ${SRC_DIR}

# Configure the container to be run as an executable
ENTRYPOINT ["/usr/src/entrypoint.sh"]
