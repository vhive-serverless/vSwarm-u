#!/bin/bash

# MIT License
#
# Copyright (c) 2022 David Schall and EASE lab
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
# Install dependencies

set -e -x

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
ROOT="$( cd $DIR && cd ../.. && pwd)"

ORG=ease-lab
REPO=vSwarm-u
OS=ubuntu-focal

if [[ ! ${GH_ACCESS_TOKEN} ]] ;
then
  echo "Error: GH_ACCESS_TOKEN needs to be set."
  exit -1;
fi;


ACCESS_TOKEN=${GH_ACCESS_TOKEN}
RESOURCES_DIR=${RESOURCES:-$ROOT/resources/}

sudo docker run --name github-build-runner \
  -d --restart=always \
  --privileged --cap-add=ALL \
  -e REPO_URL="https://github.com/${ORG}/${REPO}" \
  -e RUNNER_NAME="gem5-build-runner" \
  -e ACCESS_TOKEN=${GH_ACCESS_TOKEN} \
  -e RUNNER_WORKDIR=_work-${REPO} \
  -e RUNNER_GROUP="default" \
  -e LABELS="gem5-build,${OS_LABEL}" \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /tmp/_work-${REPO}:/tmp/_work-${REPO} \
  myoung34/github-runner:$OS