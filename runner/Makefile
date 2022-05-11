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

RUNNERS := qemu-test-runner gem5-test-runner

%-runner: Dockerfile
	DOCKER_BUILDKIT=1 docker build \
	--tag vhiveease/$@ \
	--target $@ \
	-f Dockerfile \
	.

build: $(RUNNERS)





push-%:
	docker push docker.io/vhiveease/$(subst push-,,$@):latest


run-%-runner:
	$(eval runner := $(subst run-,,$@))
	docker run --name $(runner) -d \
		--privileged --cap-add=ALL \
		-e RESOURCES=/tmp/resources/ \
		-e ACCESS_TOKEN=${ACCESS_TOKEN} \
		-v /var/run/docker.socker.sock:/var/run/docker.sock \
		-v /tmp/_work-vSwarm-u:/tmp/_work-vSwarm-u  \
		-v $(RESOURCES):/tmp/resources/ \
		vhiveease/$(runner)


stop-%-runner:
	$(eval runner := $(subst stop-,,$@))
	docker stop $(runner)
	docker rm $(runner)



## Push and image
push:
	docker push $(RUNNERS)

pull:
	docker pull $(RUNNERS)




