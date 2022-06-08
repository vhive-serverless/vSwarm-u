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
import sys
from tqdm import tqdm
import os

import argparse
def parse_arguments():
    parser = argparse.ArgumentParser(description="Script to up and download release assets")
    parser.add_argument("--file", default="release.json",help="Path to the release file")
    parser.add_argument("--download","-d", default=False, action="store_true", help = "Download release assets")
    parser.add_argument("--upload","-u", default=False, action="store_true", help = "Upload release assets")
    parser.add_argument("--version", "-v", default=False, action="store_true",help="Get release version")
    parser.add_argument("--output", "-o", type=str, default="", help="Output directory")
    return parser.parse_args()

args = parse_arguments()


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
        print("ERROR, something went wrong")


import io
import tarfile

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
    my_tar.extractall(args.output) # specify which folder to extract to
    my_tar.close()
    os.remove(tmpfile)


def downloadAsset(asset_url):
    name = asset_url.split("/")[-1]
    print("Download: " + name)
    with open(args.output + name,"wb") as f:
        download(f,asset_url)


def downloadAssets():
    with open(args.file) as f:
        artifacts = json.load(f)

    print("Download Artifacts")
    downloadAsset(artifacts["kernel"])
    downloadAsset(artifacts["client"])

    print("Download Disk image.. This could take a few minutes")
    downloadDiskImage(artifacts)

def getVersion():
    with open(args.file) as f:
        artifacts = json.load(f)
        print(artifacts["tag_name"])


if __name__ == '__main__':
    if args.version:
        getVersion()
    if args.download:
        downloadAssets()
