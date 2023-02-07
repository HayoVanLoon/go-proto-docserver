#!/usr/bin/env bash

# Copyright 2022 Hayo van Loon
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.

set -eo pipefail

TEMPLATE=customhtml.tmpl

usage() {
	echo "
Usage: ${0} -p=<path> [-t=<template>] [<excluded>...]

path		absolute path to protocol buffer directory
excluded	list of sub directories to exclude

Example:
	${0} \${PROJECT_ROOT}/apis python/.venv

Not sufficiently excluding broken or unwanted proto files may lead to errors.

"
}

[ -n "${1}" ] || (usage; exit 1)

PROTO_PATH=""
PRUNE=""

for d in "$@"; do
	case "${d}" in
	-p=*)
		PROTO_PATH=${d:3}
		continue
		;;
	-t=*)
		TEMPLATE=${d:3}
		continue
		;;
	*)
		[ -n "${PROTO_PATH}" ] || (usage; echo "Expected -p=<path>, got ${d}"; exit 1)
		;;
	esac
	[ -n "${PROTO_PATH}" ] || (echo "expected -p=PROTO_PATH"; exit 1)
	[ -d "${PROTO_PATH}" ] || (echo "'${PROTO_PATH}' is not a directory" && exit 1)

	EXCLUDE="${PROTO_PATH}/${d}"
	[ -d "${EXCLUDE}" ] || (echo "cannot exclude unknown directory '${EXCLUDE}'" && exit 1)
	echo "Excluding ${EXCLUDE}"
	PRUNE="${PRUNE} -path ${EXCLUDE} -prune -o"
done

[ -f "${TEMPLATE}" ] || (echo "template not found (${TEMPLATE})" && exit 1)

PROTO_FILES=$(find "${PROTO_PATH}" \
	-path "${PROTO_PATH}/google" -prune -o \
	${PRUNE} \
	-name '*.proto' | grep -E ".proto$" | sort)

# GOOG_FILES=$(find "${PROTO_PATH}/google" ${PRUNE} -name '*.proto' | grep -E ".proto$" | sort)
GOOG_FILES=

protoc \
	--doc_out=files \
	--doc_opt="${TEMPLATE}",index.html \
	-I"${PROTO_GOOGLEAPIS}"\
	-I"${PROTO_PATH}" \
	${PROTO_FILES} ${GOOG_FILES} || (printf "\nError generating docs\n\n" && usage && exit 1)

tidy -i -o files/index.html files/index.html || echo "Error running HTML Tidy."
