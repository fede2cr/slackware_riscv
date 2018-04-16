#!/bin/sh

# Copyright 2017  Patrick J. Volkerding, Sebeka, Minnesota, USA
# All rights reserved.
#
# Redistribution and use of this script, with or without modification, is
# permitted provided that the following conditions are met:
#
# 1. Redistributions of this script must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#
#  THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
#  WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
#  MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO
#  EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
#  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
#  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
#  OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
#  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
#  OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
#  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# Call this script with the version of the Vulkan-LoaderAndValidationLayers-sdk
# that you would like to fetch the sources for. This will fetch the SDK from
# github, and then look at the revisions listed in the external_revisions
# directory to fetch the proper glslang, SPIRV-Headers, and SPIRV-Tools.
#
# Example:  VERSION=1.1.70.0 ./fetch-sources.sh

VERSION=${VERSION:-1.1.70.0}

# Remove existing sources:
rm -rf Vulkan-LoaderAndValidationLayers-sdk* glslang-* SPIRV-Headers-* SPIRV-Tools-*

# Fetch SDK:
lftpget https://github.com/KhronosGroup/Vulkan-LoaderAndValidationLayers/archive/sdk-${VERSION}/Vulkan-LoaderAndValidationLayers-sdk-${VERSION}.tar.gz

GLSLANG_REVISION=$(tar xOf Vulkan-LoaderAndValidationLayers-sdk-${VERSION}.tar.gz Vulkan-LoaderAndValidationLayers-sdk-${VERSION}/external_revisions/glslang_revision)

git clone https://github.com/KhronosGroup/glslang.git glslang-$GLSLANG_REVISION
cd glslang-$GLSLANG_REVISION
git checkout $GLSLANG_REVISION
SPIRV_TOOLS_REVISION=$(
python3 - << EOF
import json
with open('known_good.json') as f:
  known_good = json.load(f)
commits = known_good['commits']
print(commits[0]['commit'])
EOF
)
SPIRV_HEADERS_REVISION=$(
python3 - << EOF
import json
with open('known_good.json') as f:
  known_good = json.load(f)
commits = known_good['commits']
print(commits[1]['commit'])
EOF
)
# Cleanup.  We're not packing up the whole git repo.
find . -type d -name ".git*" -exec rm -rf {} \; 2> /dev/null
cd ..
tar cf glslang-${GLSLANG_REVISION}.tar glslang-${GLSLANG_REVISION}
rm -rf glslang-${GLSLANG_REVISION}
plzip -9 glslang-${GLSLANG_REVISION}.tar

git clone https://github.com/KhronosGroup/SPIRV-Headers.git SPIRV-Headers-${SPIRV_HEADERS_REVISION}
cd SPIRV-Headers-${SPIRV_HEADERS_REVISION}
git checkout ${SPIRV_HEADERS_REVISION}
# Cleanup.  We're not packing up the whole git repo.
find . -type d -name ".git*" -exec rm -rf {} \; 2> /dev/null
cd ..
tar cf SPIRV-Headers-${SPIRV_HEADERS_REVISION}.tar SPIRV-Headers-${SPIRV_HEADERS_REVISION}
rm -rf SPIRV-Headers-${SPIRV_HEADERS_REVISION}
plzip -9 SPIRV-Headers-${SPIRV_HEADERS_REVISION}.tar

git clone https://github.com/KhronosGroup/SPIRV-Tools.git SPIRV-Tools-${SPIRV_TOOLS_REVISION}
cd SPIRV-Tools-${SPIRV_TOOLS_REVISION}
git checkout ${SPIRV_TOOLS_REVISION}
# Only purge the .pack, since spirv_tools_commit_id.h needs to query the repo:
rm -f .git/objects/pack/pack-*.pack
cd ..
tar cf SPIRV-Tools-${SPIRV_TOOLS_REVISION}.tar SPIRV-Tools-${SPIRV_TOOLS_REVISION}
rm -rf SPIRV-Tools-${SPIRV_TOOLS_REVISION}
plzip -9 SPIRV-Tools-${SPIRV_TOOLS_REVISION}.tar

# Repack Vulkan-LoaderAndValidationLayers-sdk:
gzip -d Vulkan-LoaderAndValidationLayers-sdk-${VERSION}.tar.gz
plzip -9 Vulkan-LoaderAndValidationLayers-sdk-${VERSION}.tar

# List URLs in vulkan-sdk.url:
echo "https://github.com/KhronosGroup/Vulkan-LoaderAndValidationLayers/archive/sdk-${VERSION}/Vulkan-LoaderAndValidationLayers-sdk-${VERSION}.tar.gz" > vulkan-sdk.url
echo "https://github.com/KhronosGroup/glslang/archive/${GLSLANG_REVISION}/glslang-${GLSLANG_REVISION}.tar.gz" >> vulkan-sdk.url
echo "https://github.com/KhronosGroup/SPIRV-Headers/archive/${SPIRV_HEADERS_REVISION}/SPIRV-Headers-${SPIRV_HEADERS_REVISION}.tar.gz" >> vulkan-sdk.url
echo "https://github.com/KhronosGroup/SPIRV-Tools/archive/${SPIRV_TOOLS_REVISION}/SPIRV-Tools-${SPIRV_TOOLS_REVISION}.tar.gz" >> vulkan-sdk.url

# Fix timestamps to be correct:
for file in *.tar.?z ; do
  TIMESTAMP="$(tar tvf $file | head -1 | cut -b 32-47)"
  touch -d "$TIMESTAMP" $file
done
