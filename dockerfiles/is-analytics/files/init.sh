#!/bin/sh
# ------------------------------------------------------------------------
# Copyright 2018 WSO2, Inc. (http://wso2.com)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License
# ------------------------------------------------------------------------
set -e

# custom WSO2 non-root user and group variables
user=wso2carbon
group=wso2

# file path variables
volumes=${WORKING_DIRECTORY}/volumes

# capture the Docker container IP from the container's /etc/hosts file
docker_container_ip=$(awk 'END{print $1}' /etc/hosts)

# check if the WSO2 non-root user has been created
! getent passwd ${user} >/dev/null 2>&1 && echo "WSO2 Docker non-root user does not exist" && exit 1

# check if the WSO2 non-root group has been created
! getent group ${group} >/dev/null 2>&1 && echo "WSO2 Docker non-root group does not exist" && exit 1

# check if the WSO2 non-root user home exists
test ! -d ${WORKING_DIRECTORY} && echo "WSO2 Docker non-root user home does not exist" && exit 1

# check if the WSO2 product home exists
test ! -d ${WSO2_SERVER_HOME} && echo "WSO2 Docker product home does not exist" && exit 1

# copy configuration changes and external libraries

# check if any changed configuration files have been mounted
# if any file changes have been mounted, copy the WSO2 configuration files recursively
test -d ${volumes}/repository/conf && cp -r ${volumes}/repository/conf/* ${WSO2_SERVER_HOME}/repository/conf

# check if the external library directories have been mounted
# if mounted, recursively copy the external libraries to original directories within the product home
test -d ${volumes}/repository/components/dropins && cp -r ${volumes}/repository/components/dropins/* ${WSO2_SERVER_HOME}/repository/components/dropins
test -d ${volumes}/repository/components/extensions && cp -r ${volumes}/repository/components/extensions/* ${WSO2_SERVER_HOME}/repository/components/extensions
test -d ${volumes}/repository/components/lib && cp -r ${volumes}/repository/components/lib/* ${WSO2_SERVER_HOME}/repository/components/lib

# make any runtime or node specific configuration changes
# for example, setting container IP in relevant configuration files

# set the Docker container IP as the `localMemberHost` under axis2.xml clustering configurations (effective only when clustering is enabled)
sed -i "s#<parameter\ name=\"localMemberHost\".*<\/parameter>#<parameter\ name=\"localMemberHost\">${docker_container_ip}<\/parameter>#" ${WSO2_SERVER_HOME}/repository/conf/axis2/axis2.xml

# set the ownership of the WSO2 product server home to WSO2 non-root user and group
chown -R ${user}:${group} ${WSO2_SERVER_HOME}

# start the WSO2 Carbon server
sh ${WSO2_SERVER_HOME}/bin/wso2server.sh
