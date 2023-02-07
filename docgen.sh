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

SRC=""
PRUNE=""
OUT="files"

for d in "$@"; do
	case "${d}" in
	-p=*)
		SRC=${d:3}
		continue
		;;
	-t=*)
		TEMPLATE=${d:3}
		continue
		;;
	-o=*)
		OUT=${d:3}
		continue
		;;
	*)
		[ -n "${SRC}" ] || (usage; echo "Expected -p=<path>, got ${d}"; exit 1)
		;;
	esac
	[ -n "${SRC}" ] || (echo "expected -p=SRC"; exit 1)
	[ -d "${SRC}" ] || (echo "'${SRC}' is not a directory" && exit 1)

	EXCLUDE="${SRC}/${d}"
	[ -d "${EXCLUDE}" ] || (echo "cannot exclude unknown directory '${EXCLUDE}'" && exit 1)
	echo "Excluding ${EXCLUDE}"
	PRUNE="${PRUNE} -path ${EXCLUDE} -prune -o"
done

[ -f "${TEMPLATE}" ] || (echo "template not found (${TEMPLATE})" && exit 1)

PROTO_FILES=$(find "${SRC}" \
	-path "${SRC}/google" -prune -o \
	${PRUNE} \
	-name '*.proto' | grep -E ".proto$" | sort)

# GOOG_FILES=$(find "${SRC}/google" ${PRUNE} -name '*.proto' | grep -E ".proto$" | sort)
GOOG_FILES=

protoc \
	--doc_out="${OUT}" \
	--doc_opt="${TEMPLATE}",index.html \
	-I"${PROTO_GOOGLEAPIS}"\
	-I"${SRC}" \
	${PROTO_FILES} ${GOOG_FILES} || (printf "\nError generating docs\n\n" && usage && exit 1)

tidy -i -o files/index.html files/index.html || echo "Error running HTML Tidy."
