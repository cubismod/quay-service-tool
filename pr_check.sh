#!/bin/bash
set -exv

BASE_IMG="quay-service-tool"

IMG="${BASE_IMG}:pr-check"

docker build -t "${IMG}" -f Dockerfile .
