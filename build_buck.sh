#!/bin/bash

# Set Java 8 environment variables
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export PATH=$JAVA_HOME/bin:$PATH

# Run buck with all arguments passed to this script
./buck.pex "$@" 