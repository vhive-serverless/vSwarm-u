#!/bin/bash
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
# This script accepts the following parameters:
#
# * owner
# * repo
# * tag
# * filename
# * github_api_token
#
# Script to upload a release asset using the GitHub API v3.
#
# Example:
#
# artifacts.sh GITHUB_TOKEN RELEASE_ID=68604631 owner=stefanbuck repo=playground tag=v0.1.0 filename=./build.zip
#

GITHUB_TOKEN=$GITHUB_TOKEN
RELEASE_ID=${RELEASE_ID-68604631}
owner=vhive-serverless
repo=vSwarm-u
folder=artifacts
size=500m


set -e -x
# Check dependencies.
TST=$(which jq || sudo apt install jq)
TST=$(which pigz || sudo apt install pigz)




## Get release info
if [[ -z "{TAG_NAME}" ]]; then
	curl -s https://api.github.com/repos/$owner/$repo/releases | jq '.[] | select(.id=='$RELEASE_ID')' > info.json
	TAG_NAME=$(cat info.json | jq -r '.tag_name')
fi;



# DOWNLOAD_URL=$(dirname $(cat info.json | jq -r '.assets[0].browser_download_url'))
DOWNLOAD_URL="https://github.com/$owner/$repo/releases/download/$TAG_NAME"
UPLOAD_URL="https://uploads.github.com/repos/$owner/$repo/releases/$RELEASE_ID"



function upload {
	file=$1
	asset_name=$1
	[ $# == 2 ] && asset_name=$2

	UPLOAD_URL="https://uploads.github.com/repos/$owner/$repo/releases/$RELEASE_ID"

	curl -X POST \
		-H "Content-Type: $(file -b --mime-type $file)" \
    	-T "$1" \
    	-H "Authorization: token $GITHUB_TOKEN" \
    	-H "Accept: application/vnd.github.v3+json" \
    	$UPLOAD_URL/assets?name=$asset_name > response 2>&1

	# Check response
	if $(grep -q created_at response) ; then
		echo "Upload successfull"
	else
		echo "Upload fail";
		cat response;
		exit 1;
	fi
	rm response
}


function download {
	file=$1
	asset_name=$1
	[ $# == 2 ] && asset_name=$2

	DOWNLOAD_URL="https://github.com/$owner/$repo/releases/download/$TAG_NAME"

	curl -L $DOWNLOAD_URL/$asset_name \
    -o $file
}




function compress-split {
	file=$1

	## Create checksum
	shasum -a 256 ${file} > $1.sums

	## Compress
	# tar cvzf tmp.tar.gz ${file}
	## Compress parallel
	tar c ${file} | pigz -c > tmp.tar.gz

	## Split
	split -b $size tmp.tar.gz ${file}.tar.gz.

	rm tmp.tar.gz
}

function decompress-split {
	file=$1

	## Combine splits
	cat ${file}.tar.gz.* > tmp2.tar.gz

	## Uncompress
	# tar xzvf tmp2.tar.gz
	## Uncompress parallel
	pigz -cd tmp2.tar.gz | tar xf -
	rm tmp2.tar.gz

	## Verify checksum
	shasum -a 256 -c ${file}.sums
	# ## Remove archives
	# rm *.tar.gz.* tmp2.tar.gz *.sums
}

function compress-split-disk {
	disk=$1
	asset_name=$1
	[ $# == 2 ] && asset_name=$2

	## Create folder
	mkdir -p $asset_name && cp $disk $asset_name

	pushd $asset_name > /dev/null
	# Compress
	compress-split $disk
	rm $disk
	popd > /dev/null
}


function upload-disk {
	disk=$1
	asset_name=$1
	[ $# == 2 ] && asset_name=$2

	## Create folder
	mkdir -p tmpup && cp $disk tmpup/$asset_name

	pushd tmpup > /dev/null
	# Compress
	compress-split $asset_name
	rm $asset_name

	for f in *; do
		echo Upload $f
		upload $f $f
	done
	popd > /dev/null
	rm -r tmpup
}


function upload-files-in-dir {
	dir=$1
	asset_name=$1
	[ $# == 2 ] && asset_name=$2

	## Create folder
	mkdir -p tmpup && cp $dir/* tmpup/

	pushd tmpup > /dev/null

	for f in *; do
		echo Upload $f
		upload $f $f
	done
	popd > /dev/null
	rm -r tmpup
}

# upload-disk $1



################ Download ####################


function download-disk {

	disk=$1
	asset_name=$1
	[ $# == 2 ] && asset_name=$2

	curl -s https://api.github.com/repos/$owner/$repo/releases | jq '.[] | select(.tag_name=="'$TAG_NAME'")' > info.json
	FILES=$(jq -r '.assets[] | select(.name | match("'$asset_name'")) | .browser_download_url' info.json)

	mkdir -p tmpdn
	pushd tmpdn > /dev/null

	for f in $FILES; do
		url1=$(dirname $f)
		file=$(basename $f)

		echo Download $file
		curl -L $f -o $file
	done

	decompress-split $asset_name
	popd > /dev/null
	cp tmpdn/$asset_name $disk

	rm -r tmpdn
}


if declare -f "$1" > /dev/null
then
	# call arguments verbatim
	"$@"
else
	# Helper
	echo "Helper functions to manage uploading and downloading artifacts"
	echo "call './artifacts <upload/download>-disk <name>' to up/download disk image"
	exit 1
fi