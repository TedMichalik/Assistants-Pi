#!/bin/bash
# Copyright 2017 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
set -o errexit

scripts_dir="$(dirname "${BASH_SOURCE[0]}")"
GIT_DIR="$(realpath $(dirname ${BASH_SOURCE[0]})/..)"

# make sure we're running as the owner of the checkout directory
RUN_AS="$(ls -ld "$scripts_dir" | awk 'NR==1 {print $3}')"
if [ "$USER" != "$RUN_AS" ]
then
    echo "This script must run as $RUN_AS, trying to change user..."
    exec sudo -u $RUN_AS $0
fi
clear
echo ""
read -r -p "Enter the your full credential file name including the path and .json extension: " credname
echo ""
read -r -p "Enter the your Google Cloud Console Project-Id: " projid
echo ""
read -r -p "Enter the modelid that was generated in the actions console: " modelid
echo ""
echo "Your Model-Id: $modelid Project-Id: $projid used for this project" >> /home/${USER}/modelid.txt

cd /home/${USER}/
echo ""
echo ""
echo "Changing particulars in service files"
sed -i 's/created-project-id/'$projid'/g' ${GIT_DIR}/systemd/google-assistant.service
sed -i 's/saved-model-id/'$modelid'/g' ${GIT_DIR}/systemd/google-assistant.service
sed -i 's/__USER__/'${USER}'/g' ${GIT_DIR}/systemd/google-assistant.service

sudo apt-get install portaudio19-dev libffi-dev libssl-dev

python3.9 -m venv env
source env/bin/activate

pip install --upgrade pip setuptools wheel
pip install --upgrade google-assistant-sdk[samples]
pip install protobuf==3.19.6
pip install --upgrade tenacity
pip install RPi.GPIO

google-oauthlib-tool --scope https://www.googleapis.com/auth/assistant-sdk-prototype \
          --scope https://www.googleapis.com/auth/gcm \
          --save --client-secrets $credname
echo ""
