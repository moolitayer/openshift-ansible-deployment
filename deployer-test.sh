#!/usr/bin/env bash

#
# Run from the parent library of this repo
# ./openshift-ansible-deployment/deployer-test.sh
#

BUILD_ID=8
OPENSHIFT_ANSIBLE_REF=openshift-ansible-3.6.140-1
MASTER_IP=10.35.48.159
INFRA_IPS=10.35.48.120
COMPUTE_IPS=10.35.48.121
WORKSPACE=$(realpath ../test_workspace)
ROOT_PASSWORD=""
rm -rf ${WORKSPACE}/*
mkdir ${WORKSPACE}

. ./deployer.sh