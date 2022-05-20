# MIT License

# Copyright (c) 2022 EASE lab

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.


RESOURCES 	?=$(ROOT)/resources/
ACCESS_TOKEN :=${GH_ACCESS_TOKEN}

RUNNERS := gem5-build-runner qemu-test-runner gem5-test-runner


#### Build the runner images
%-runner: Dockerfile
	DOCKER_BUILDKIT=1 docker build \
	--tag vhiveease/$@ \
	--target $@ \
	-f Dockerfile \
	.

build: $(RUNNERS)

start-all: start-test-runners start-build-runners
stop-all: stop-test-runners stop-build-runners



## Push and pull
push-%:
	docker push docker.io/vhiveease/$(subst push-,,$@):latest

push:
	docker push $(RUNNERS)

pull:
	docker pull $(RUNNERS)



#@$(eval runner_name := "$(runner)-$(shell echo $$RANDOM | md5sum | head -c 10; echo;)")

##### Start and stop runners ####
# Test runners
start-test-runners: start-qemu-test-runner start-gem5-test-runner
stop-test-runners: stop-qemu-test-runner stop-gem5-test-runner

start-%-test-runner:
	@$(eval runner := $(subst start-,,$@))
	@$(eval runner_name := "$(runner)-$(shell echo $$RANDOM | md5sum | head -c 10; echo;)")
	echo $(runner_name)
	docker run --name $(runner_name) -d \
		--privileged --cap-add=ALL \
		-e RESOURCES=/tmp/resources/ \
		-e RUNNER_NAME=$(runner_name) \
		-e ACCESS_TOKEN=${ACCESS_TOKEN} \
		-v /var/run/docker.socker.sock:/var/run/docker.sock \
		-v /tmp/_work-vSwarm-u:/tmp/_work-vSwarm-u  \
		-v $(RESOURCES):/tmp/resources/ \
		vhiveease/$(runner)


# Build runners
start-build-runners: start-gem5-build-runner
stop-build-runners: stop-gem5-build-runner

start-gem5-build-runner:
	@$(eval runner := gem5-build-runner)
	@$(eval runner_name := "$(runner)-$(shell echo $$RANDOM | md5sum | head -c 10; echo;)")
	echo $(runner_name)
	docker run --name $(runner_name) -d \
		--privileged --cap-add=ALL \
		-e RUNNER_NAME=$(runner_name) \
		-e ACCESS_TOKEN=${ACCESS_TOKEN} \
		-v /var/run/docker.socker.sock:/var/run/docker.sock \
		-v /tmp/_work-vSwarm-u:/tmp/_work-vSwarm-u  \
		vhiveease/$(runner)


stop-%-runner:
	$(eval runner := $(subst stop-,,$@))
	$(eval runners := $(shell docker container ls -a -q --filter "ancestor=vhiveease/$(runner)"))
	echo "Stop $(runners) $$(expr length "$(runners)")"
	if [ $$(expr length "$(runners)") -gt 0 ]; then \
	docker stop $(runners); \
	docker rm $(runners); \
	fi;

# stop-all:








