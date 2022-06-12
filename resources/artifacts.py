#!/bin/python
#
# MIT License
#
# Copyright (c) 2022 EASE lab, University of Edinburgh
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
#
# Author: David Schall

import requests
import json
import tarfile
from tqdm import tqdm
import os
import tarfile
import shutil
import logging as log

RESOURCES = os.environ['RESOURCES']
if RESOURCES == "":
    log.warning(" 'RESOURCES' variable not set!!")

import argparse

parser = argparse.ArgumentParser(description="Script to up and download release assets")
parser.add_argument("--file", default=f"{RESOURCES}/release.json",
                    help="Path to the release file. Default 'resources/release.json'")
parser.add_argument("--download","-d", default=False, action="store_true", help = "Download release assets")
# parser.add_argument("--upload","-u", default=False, action="store_true", help = "Upload release assets")
parser.add_argument("--version", "-v", default=False, action="store_true",help="Get release version")
parser.add_argument("--output", "-o", type=str, default=f"{RESOURCES}/",
                    help="Output directory to store the assets to. Default: 'resources/'")
args = parser.parse_args()


def download(f,url):
    # Streaming, so we can iterate over the response.
    response = requests.get(url, stream=True)
    total_size_in_bytes= int(response.headers.get('content-length', 0))
    # print(total_size_in_bytes)
    block_size = 1024 #1 Kibibyte
    progress_bar = tqdm(total=total_size_in_bytes, unit='iB', unit_scale=True)

    # response.raw.read(block_size)
    for data in response.iter_content(block_size):
        progress_bar.update(len(data))
        f.write(data)

    progress_bar.close()
    if total_size_in_bytes != 0 and progress_bar.n != total_size_in_bytes:
        log.error("ERROR, something went wrong")




## Download disk
def downloadDiskImage(release_assets):
    urls = release_assets["disk-image"]
    tmpfile="disk.tmp"
    # progress = tqdm(range(len(urls)+1))
    with open(tmpfile,'wb') as f:
        for i,url in enumerate(urls):
            name = url.split("/")[-1]
            print(f"Download: {i+1}/{len(urls)} " + name)
            # progress.set_description("Download %s: %s" % (i, name))
            download(f,url)

    print("Extract Disk: ")
    my_tar = tarfile.open(tmpfile,"r:gz")
    my_tar.extractall("") # specify which folder to extract to
    my_tar.close()
    os.remove(tmpfile)


def downloadAsset(asset_url):
    name = asset_url.split("/")[-1]
    print("Download: " + name)
    with open(name,"wb") as f:
        download(f,asset_url)


def downloadAssets():
    with open(args.file) as f:
        artifacts = json.load(f)

    print("Download Artifacts")
    downloadAsset(artifacts["kernel"])
    downloadAsset(artifacts["client"])

    print("Download Disk image.. This could take a few minutes")
    downloadDiskImage(artifacts)

def moveAssets():
    with open(args.file) as f:
        artifacts = json.load(f)

    ## Move assets to destination
    print("Copy artifacts to: " + args.output)
    name, artifact_name = "kernel", artifacts["kernel"].split("/")[-1]
    shutil.move(artifact_name, args.output + name)
    name, artifact_name = "client", artifacts["client"].split("/")[-1]
    shutil.move(artifact_name, args.output + name)
    name, artifact_name = "disk-image.qcow2", artifacts["disk-image"][0].split("/")[-1].split(".")[0]
    shutil.move(artifact_name, args.output + name)


def getVersion():
    with open(args.file) as f:
        artifacts = json.load(f)
        print(artifacts["tag_name"])


if __name__ == '__main__':
    if args.version:
        getVersion()
    elif args.download:
        downloadAssets()
        moveAssets()
    else:
        log.warning(" You don't want me to do something?")
        parser.print_help()
