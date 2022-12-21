---
layout: default
title: Miscallerous
parent: main
nav_order: 1
---


#### Build disk image with self-hosted runner

1. Start two machines in cloudlab, one based on arm (m400) and one x86 (x170) machine.

2. From the client machine start the self hosted runners using the `create-build-runner.yaml` in the `runner` folder.

The `runner` folder contains two scripts to start a test and a build runner. It requires ansible to be installed.

```
cd `runner`
GH_ACCESS_TOKEN=<Token> ansible-playbook --private-key <ssh/key> -v -u <cloudlab/user> -i <Host>, ${PWD}/create-build-runner.yaml

```

3. Once the runners are registered in Github trigger the workflows:
- __create-build-runner.yaml__ and __create_base_disk_self_hosted_arm.yml__.



#### Make release
1. Update the `VERSION` in `resources/Makefile` and commit.
2. Make sure all artifact workflows completed successfully. (kernel, disk-image and test-client)
3. Release with:

```
make -f resources/Makefile release
```
The current commit will tagged and the tag will be pushed. This will trigger the __release.yaml__ workflow which will gather all artifacts and add them to a new created release.

> You can also trigger the release workflow manualy. Note that this will automatically create a tag like: `refs/tags/refs/heads/xxxxxx` with the branch name. If you now push changes it might fail. For making further changes you need to delete the remote tag: like `git push origin :refs/tags/refs/heads/release-v2`
https://devconnected.com/how-to-delete-local-and-remote-tags-on-git/