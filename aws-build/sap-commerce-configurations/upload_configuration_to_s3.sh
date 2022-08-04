#!/usr/bin/env bash

# Copyright 2022 Amazon.com, Inc. or its affiliates. All Rights Reserved.

### This script helps to upload the environments configuration to the s3 bucket

bucket=$1
aws s3 cp environments s3://$bucket/environments --recursive
