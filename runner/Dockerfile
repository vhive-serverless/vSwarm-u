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



# DIR=/tmp/_work-${REPO}
# mkdir -p $DIR


# # hadolint ignore=DL3007
# FROM myoung34/github-runner-base:latest
# LABEL maintainer="myoung34@my.apsu.edu"

# ENV AGENT_TOOLSDIRECTORY=/opt/hostedtoolcache
# RUN mkdir -p /opt/hostedtoolcache

# ARG GH_RUNNER_VERSION="2.289.1"
# ARG TARGETPLATFORM

# SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# WORKDIR /actions-runner
# COPY install_actions.sh /actions-runner

# # TODO: remove this terrible sed once
# #  https://github.com/actions/runner/pull/1585 is merged or similar
# RUN chmod +x /actions-runner/install_actions.sh \
#   && sed -i.bak 's/.\/bin\/installdependencies.sh/wget https:\/\/raw.githubusercontent.com\/myoung34\/runner\/main\/src\/Misc\/layoutbin\/installdependencies.sh -O .\/bin\/installdependencies.sh; bash .\/bin\/installdependencies.sh/g' /actions-runner/install_actions.sh \
#   && /actions-runner/install_actions.sh ${GH_RUNNER_VERSION} ${TARGETPLATFORM} \
#   && rm /actions-runner/install_actions.sh

# COPY token.sh entrypoint.sh ephemeral-runner.sh /
# RUN chmod +x /token.sh /entrypoint.sh /ephemeral-runner.sh

# ENTRYPOINT ["/entrypoint.sh"]
# CMD ["./bin/Runner.Listener", "run", "--startuptype", "service"]


#---------- Build runner -----------#
ARG OS=ubuntu-focal
FROM myoung34/github-runner:$OS as vswarm-u-build-runner

# Install dependencies
RUN  apt-get update \
  && apt-get install -y \
      build-essential git m4 scons zlib1g zlib1g-dev \
    	libprotobuf-dev protobuf-compiler libprotoc-dev libgoogle-perftools-dev \
    	python3-dev python3-six python-is-python3 libboost-all-dev pkg-config \
      qemu-kvm bridge-utils \
  && apt-get install -y \
      python3-pip \
      curl wget \
      lsof \
      qemu-kvm bridge-utils \
  && rm -rf /var/lib/apt/lists/*


ARG ORG=ease-lab \
    REPO=vSwarm-u \
    OS_LABEL=ubuntu-20.04

ENV REPO_URL=https://github.com/$ORG/$REPO \
    RUNNER_NAME="vswarm-u-build-runner" \
    ACCESS_TOKEN="${GH_ACCESS_TOKEN}" \
    RUNNER_WORKDIR=_work-$REPO \
    RUNNER_GROUP="default" \
    LABELS="vswarm-u-build" \
    GIT_SSL_NO_VERIFY=1


ENTRYPOINT ["/entrypoint.sh"]
CMD ["./bin/Runner.Listener", "run", "--startuptype", "service"]




#---------- Qemu test runner -----------#
# First stage (Builder):
ARG OS=ubuntu-focal
FROM myoung34/github-runner:$OS as qemu-test-runner

ARG ORG=ease-lab \
    REPO=vSwarm-u \
    OS_LABEL=ubuntu-20.04

ENV REPO_URL=https://github.com/$ORG/$REPO \
    RUNNER_NAME="qemu-test-runner" \
    ACCESS_TOKEN="${GH_ACCESS_TOKEN}" \
    RUNNER_WORKDIR=_work-$REPO \
    RUNNER_GROUP="default" \
    LABELS="qemu-test" \
    RESOURCES=/tmp/resources

# Install dependencies
RUN  apt-get update \
  && apt-get install -y \
        python3-pip \
        curl \
        lsof \
        qemu-kvm bridge-utils \
  && rm -rf /var/lib/apt/lists/*


# Install the upload server
RUN python3 -m pip install --user uploadserver


ENTRYPOINT ["/entrypoint.sh"]
CMD ["./bin/Runner.Listener", "run", "--startuptype", "service"]





#---------- gem5 test runner -----------#
ARG OS=ubuntu-focal
FROM myoung34/github-runner:$OS as gem5-test-runner

# Install dependencies
RUN  apt-get update \
  && apt-get install -y \
      build-essential git m4 scons zlib1g zlib1g-dev \
    	libprotobuf-dev protobuf-compiler libprotoc-dev libgoogle-perftools-dev \
    	python3-dev python3-six python-is-python3 libboost-all-dev pkg-config \
  && apt-get install -y \
        python3-pip \
        curl \
        lsof \
        qemu-kvm bridge-utils \
  && rm -rf /var/lib/apt/lists/*

ARG ORG=ease-lab \
    REPO=vSwarm-u \
    OS_LABEL=ubuntu-20.04

ENV REPO_URL=https://github.com/$ORG/$REPO \
    RUNNER_NAME="gem5-test-runner" \
    ACCESS_TOKEN="${GH_ACCESS_TOKEN}" \
    RUNNER_WORKDIR=_work-$REPO \
    RUNNER_GROUP="default" \
    LABELS="gem5-test" \
    RESOURCES=/tmp/resources

ENTRYPOINT ["/entrypoint.sh"]
CMD ["./bin/Runner.Listener", "run", "--startuptype", "service"]






#---------- gem5 arm runner -----------#
ARG OS=ubuntu-focal
FROM myoung34/github-runner:$OS as gem5-test-runner

ARG ORG=ease-lab \
    REPO=vSwarm-u \
    OS_LABEL=ubuntu-20.04

ENV REPO_URL=https://github.com/$ORG/$REPO \
    RUNNER_NAME="gem5-test-runner" \
    ACCESS_TOKEN="${GH_ACCESS_TOKEN}" \
    RUNNER_WORKDIR=_work-$REPO \
    RUNNER_GROUP="default" \
    LABELS="gem5-test" \
    RESOURCES=/tmp/resources

# Install dependencies
RUN  apt-get update \
  && apt-get install -y \
      build-essential git m4 scons zlib1g zlib1g-dev \
    	libprotobuf-dev protobuf-compiler libprotoc-dev libgoogle-perftools-dev \
    	python3-dev python3-six python-is-python3 libboost-all-dev pkg-config \
  && apt-get install -y \
        python3-pip \
        curl \
        lsof \
        qemu-kvm bridge-utils \
  && rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["/entrypoint.sh"]
CMD ["./bin/Runner.Listener", "run", "--startuptype", "service"]