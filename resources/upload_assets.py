#!/bin/python3
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

import time
import subprocess
import sys
import mimetypes
import argparse
import requests
from requests.adapters import *
import tarfile
from tqdm import tqdm
import os
import logging as log

RESOURCES = os.getenv("RESOURCES")
if RESOURCES and RESOURCES == "":
    log.warning(" 'RESOURCES' variable not set!!")


parser = argparse.ArgumentParser(
    description="Script to up and download release assets")
parser.add_argument("--kernel", default=f"{RESOURCES}/kernel",
                    help="Path to kernel")
parser.add_argument("--disk-image", default=f"{RESOURCES}/disk-image",
                    help="Path to disk-image")
parser.add_argument("--client", default=f"{RESOURCES}/client",
                    help="Path to client")
parser.add_argument("--upload-url", default="", help="Upload URL.")
parser.add_argument("--tag-name", default="", help="TAG name")
parser.add_argument("--release-id", default="", help="Release ID")
# parser.add_argument("--upload","-u", default=False, action="store_true", help = "Upload release assets")
parser.add_argument("--version", "-v", default=False,
                    action="store_true", help="Get release version")
args = parser.parse_args()


# Written for Github actions when release created event is triggered.
GITHUB_TOKEN = os.environ["GITHUB_TOKEN"]
# GITHUB_TAGNAME = os.environ["TAG_NAME"]

GITHUB_REPOSITORY = "ease-lab/vSwarm-u"



# token = os.getenv('GITHUB_TOKEN')
# g = Github(token)
# repo = g.get_repo("ease-lab/vSwarm-u")


# List releases for a repository:
# https://developer.github.com/v3/repos/releases/#list-releases-for-a-repository
RELEASES_API = "https://api.github.com/repos/" + GITHUB_REPOSITORY + "/releases"

# The path of assets, eg. "out/".
OUT_FILES_PATH = "out/"


def get_release(tag_name="latest",id=None):

    print("Releases API: " + RELEASES_API)

    headers = {
        'Authorization': 'token ' + GITHUB_TOKEN,
    }

    response = requests.get(RELEASES_API, headers=headers)

    print("debug: " + str(response.status_code))

    RELEASES = response.json()
    RELEASES_LEN = len(RELEASES)

    for i in range(0, RELEASES_LEN):
        if id and RELEASES[i]["id"] or \
            GITHUB_TAGNAME != "" and RELEASES[i]["tag_name"] == GITHUB_TAGNAME:
            RELEASES_NUMBER = i
            break

    try:
        print("Found the target tagname, " + str(RELEASES_NUMBER))

    except:
        print("Can't found the target tagname.")
        sys.exit(1)

    return RELEASES[RELEASES_NUMBER]


def get_uploadurl(release):
    global UPLOAD_URL
    UPLOAD_URL = release["upload_url"].replace(u'{?name,label}', '')

    print("Upload URL: " + UPLOAD_URL)
    return UPLOAD_URL


def get_assets(release):
    # print(release["assets"])
    assets = []
    for a in release["assets"]:
        assets += [{"name": a["name"], "url": a["browser_download_url"]}]

    return assets


def compress(tar_file, members):
    """
    Adds files (`members`) to a tar_file and compress it
    """
    # open file for gzip compressed writing
    tar = tarfile.open(tar_file, mode="w:gz")

    # with progress bar
    # set the progress bar
    progress = tqdm(members)
    for member in progress:
        # add file/folder/link to the tar file (compress)
        tar.add(member)
        # set the progress description of the progress bar
        progress.set_description(f"Compressing {member}")
    # close the file
    tar.close()


def spinning_cursor():
    while True:
        for cursor in '|/-\\':
            yield cursor


def compressParallel(tar_file, file):
    print(f"Compress file: {file} -> {tar_file}")
    args = ["tar", "--use-compress-program=pigz", "-cf", tar_file, file]
    # subprocess.call(args=args)
    p = subprocess.Popen(args)

    spinner = spinning_cursor()
    while p.poll() is None:
        sys.stdout.write('\r')
        sys.stdout.write("Compressing... " + next(spinner))
        sys.stdout.flush()
        time.sleep(0.2)


def split(filename, size="500m", outname=""):
    if outname == "":
        outname = filename + "."
    print(f"Split file: {filename} -> {outname}xx")
    args = ["split", "-b", size, filename, outname]
    subprocess.call(args=args)


# def post_with_retries(url: str, data: dict, retries: int, backoff: float) -> int:
#     """
#     Make a POST request with retries.

#     >>> post_with_retries('http://httpstat.us/503', {}, retries=1, backoff=0)
#     500
#     >>> post_with_retries('https://httpstat.us/200', {}, retries=1, backoff=0)
#     200
#     """
#     retry_adapter = HTTPAdapter(max_retries=Retry(
#         total=retries,
#         backoff_factor=backoff,
#         status_forcelist=[500, 502, 503, 504],
#         method_whitelist=frozenset(['POST'])
#     ))

#     with requests.Session() as session:
#         session.mount('http://', retry_adapter)
#         session.mount('https://', retry_adapter)

#         try:
#             response = session.post(url, data=data)
#         except RetryError:
#             return 500

#         return response.status_code



def upload_asset(path, name="", **kwargs):
    print("Upload asset: " + path)

    # Upload a release asset:
    # https://developer.github.com/v3/repos/releases/#upload-a-release-asset

    # `Content-Type` is required, use `mimtypes` to guess the file's mimetype.
    MIMETYPE = mimetypes.guess_type(OUT_FILES_PATH + path)[0]

    # Use `application/octet-stream` for an unknown file type.
    if MIMETYPE is None:
        MIMETYPE = "application/octet-stream"

    print("Mimetype: " + MIMETYPE)

    headers = {
        'Authorization': 'token ' + GITHUB_TOKEN,
        'Content-Type': MIMETYPE,
        'Accept': "application/vnd.github.v3+json",
    }

    params = (
        ('name', name if name != "" else path),
    )

    data = open(path, 'rb').read()

    retry_adapter = HTTPAdapter(max_retries=Retry(
        total=7,
        # backoff_factor=0,
        # status_forcelist=[500, 502, 503, 504],
        # method_whitelist=frozenset(['POST'])
    ))

    with requests.Session() as session:
        # session.mount('http://', retry_adapter)
        session.mount('https://', retry_adapter)

        try:
            response = session.post(UPLOAD_URL, headers=headers,
                            params=params, data=data, **kwargs)
        except RetryError:
            return 500

    # response = requests.post(UPLOAD_URL, headers=headers,
    #                          params=params, data=data, **kwargs)

    # print("debug: " + str(response.status_code) + "\ndebug:\n" + str(response.text))

    # Response for successful upload: 201 Created
    # https://developer.github.com/v3/repos/releases/#response-for-successful-upload
    if response.status_code == 201:
        return True
    return False


def upload_disk(dir, prefix):
    OUT_FILES = os.listdir(dir)
    disk_files = [f for f in OUT_FILES if prefix in f]
    disk_files_num = len(disk_files)
    print("Disks: " + str(disk_files) +
          "\nNumber of files: " + str(disk_files_num))

    FAILURE_MARK = "0"

    for i in range(0, disk_files_num):
        FILENAME = disk_files[i]
        print("Current asset: " + FILENAME)

        if upload_asset(path=dir+"/"+FILENAME, name=f"disk-image-{i}", timeout=50):
            print("\033[1;32;40m" + FILENAME + ": success. " +
                  str(i+1) + "/" + str(disk_files_num) + "\033[0m")

        else:
            print("\033[1;31;40m" + FILENAME + ": fail. " +
                  str(i+1) + "/" + str(disk_files_num) + "\033[0m")
            FAILURE_MARK = "1"

    if FAILURE_MARK == "0":
        print("\033[1;32;40m All assets uploaded success fully\033[0m")

    elif FAILURE_MARK == "1":
        print("\033[1;31;40m Fail for uploading all \033[0m")



if __name__ == '__main__':
    global GITHUB_TAGNAME
    GITHUB_TAGNAME = args.tag_name


    release = get_release(tag_name=GITHUB_TAGNAME, id=args.release_id)
    get_uploadurl(release)
    print(UPLOAD_URL)
    # if args.upload_url == "":
    #     UPLOAD_URL=get_uploadurl(release)
    # else:
    #     UPLOAD_URL=get_uploadurl(release)

    print("Upload Kernel")
    file = args.kernel
    name = "vmlinux-amd64"
    upload_asset(path=file, name=name, timeout=10)

    print("Upload Client")
    file = args.client
    name = "client-amd64"
    upload_asset(path=file, name=name, timeout=10)

    print("Compress and Split disk-image")
    filename = args.disk_image
    tmpfile = "tmp"
    prefix = "disk-image-amd64-"

    compressParallel(tmpfile, filename)
    split(tmpfile, outname=prefix)
    os.remove(tmpfile)

    print("Upload disk-image")
    upload_disk(".", prefix=prefix)

    release = get_release(tag_name=GITHUB_TAGNAME, id=args.release_id)
    get_uploadurl(release)
    print(get_assets(release))
