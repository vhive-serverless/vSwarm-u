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

set -e -x

PWD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

REMOTE=hp150.utah.cloudlab.us
COUNT=2
AS_USER=dschall
PRIVATE_KEY=${4:-}

# sudo apt update -qq
# sudo apt install software-properties-common
# sudo add-apt-repository --yes --update ppa:ansible/ansible
# sudo apt install -q ansible


GH_ACCESS_TOKEN=${GH_ACCESS_TOKEN} ansible-playbook -vvv --private-key ~/.ssh/id_cloudlab -u $AS_USER -i ${REMOTE}, ${PWD}/setup-host.yaml

# # ansible-playbook --private-key ~/.ssh/id_cloudlab -u $AS_USER -i ${REMOTE}, ${PWD}/delete-runners.yaml

# for i in $(seq ${COUNT}); do
#     GH_ACCESS_TOKEN=${GH_ACCESS_TOKEN} ansible-playbook --private-key ~/.ssh/id_cloudlab -u $AS_USER -i ${REMOTE}, ${PWD}/create-runner.yaml
#     # ansible-playbook --private-key ~/.ssh/id_cloudlab -u dschall -i pc01.cloudlab.umass.edu, create-runner.yaml
# done
