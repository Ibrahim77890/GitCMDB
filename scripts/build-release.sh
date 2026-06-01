#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="${ROOT_DIR}/dist"
STAGE_DIR="${DIST_DIR}/gitcmdb"
TARBALL="gitcmdb-linux-amd64.tar.gz"

rm -rf "${DIST_DIR}"
mkdir -p "${STAGE_DIR}"

cp -R "${ROOT_DIR}/bin" "${STAGE_DIR}/"
cp -R "${ROOT_DIR}/lib" "${STAGE_DIR}/"
cp -R "${ROOT_DIR}/schemas" "${STAGE_DIR}/"
cp -R "${ROOT_DIR}/scripts" "${STAGE_DIR}/"
cp -R "${ROOT_DIR}/man" "${STAGE_DIR}/"
cp -R "${ROOT_DIR}/docs" "${STAGE_DIR}/"
cp "${ROOT_DIR}/install.sh" "${STAGE_DIR}/"
cp "${ROOT_DIR}/README.md" "${STAGE_DIR}/"
cp "${ROOT_DIR}/LICENSE" "${STAGE_DIR}/"
cp "${ROOT_DIR}/CHANGELOG.md" "${STAGE_DIR}/"

chmod +x "${STAGE_DIR}/bin/gitcmdb" "${STAGE_DIR}/bin/gitcmdb.sh"

(
  cd "${DIST_DIR}"
  tar -czf "${TARBALL}" gitcmdb
  sha256sum "${TARBALL}" > SHA256SUMS
)

echo "Release artifacts created in ${DIST_DIR}"
