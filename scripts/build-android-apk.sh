#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${1:-${ROOT_DIR}/dist/android}"
APP_ID="${APP_ID:-com.openspeedtest.app}"
APP_NAME="${APP_NAME:-OpenSpeedTest}"
PACKAGE_TYPE="${PACKAGE_TYPE:-debug}"
ANDROID_PLATFORM="${ANDROID_PLATFORM:-android-34}"
ANDROID_BUILD_TOOLS="${ANDROID_BUILD_TOOLS:-34.0.0}"
JAVA_HOME="${JAVA_HOME:-}"
ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-}}"

WORK_DIR="$(mktemp -d)"
cleanup() {
  rm -rf "${WORK_DIR}"
}
trap cleanup EXIT

if ! command -v node >/dev/null 2>&1; then
  echo "Node.js is required (node not found)." >&2
  exit 1
fi

if ! command -v npm >/dev/null 2>&1; then
  echo "npm is required (npm not found)." >&2
  exit 1
fi

if [[ -z "${JAVA_HOME}" ]] && command -v javac >/dev/null 2>&1; then
  JAVA_HOME="$(dirname "$(dirname "$(command -v javac)")")"
  export JAVA_HOME
fi

if [[ -z "${JAVA_HOME}" ]]; then
  echo "JAVA_HOME is required (Java JDK 17+ not detected)." >&2
  exit 1
fi

if [[ -z "${ANDROID_SDK_ROOT}" ]]; then
  echo "ANDROID_SDK_ROOT (or ANDROID_HOME) is required." >&2
  exit 1
fi

if command -v sdkmanager >/dev/null 2>&1; then
  yes | sdkmanager "platforms;${ANDROID_PLATFORM}" "build-tools;${ANDROID_BUILD_TOOLS}" >/dev/null
fi

echo "Creating Cordova project in ${WORK_DIR}" >&2
npx --yes cordova create "${WORK_DIR}/app" "${APP_ID}" "${APP_NAME}"

cd "${WORK_DIR}/app"

npx --yes cordova platform add android
npx --yes cordova plugin add cordova-plugin-whitelist

rm -rf www/*

cp "${ROOT_DIR}/index.html" www/
cp "${ROOT_DIR}/hosted.html" www/
cp "${ROOT_DIR}/downloading" www/
cp "${ROOT_DIR}/upload" www/
cp -R "${ROOT_DIR}/assets" www/

if [[ "${PACKAGE_TYPE}" == "release" ]]; then
  npx --yes cordova build android --release
else
  npx --yes cordova build android --debug
fi

APK_PATH=$(find "${WORK_DIR}/app/platforms/android/app/build/outputs/apk" -type f -name "*.apk" | head -n 1)
if [[ -z "${APK_PATH}" ]]; then
  echo "APK not found. Check the Cordova build output for errors." >&2
  exit 1
fi

mkdir -p "${OUT_DIR}"
cp "${APK_PATH}" "${OUT_DIR}/"

echo "APK generated at: ${OUT_DIR}/$(basename "${APK_PATH}")"
