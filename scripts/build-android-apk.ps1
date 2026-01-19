Param(
  [string]$OutDir = "dist/android"
)

$ErrorActionPreference = "Stop"

$rootDir = Resolve-Path (Join-Path $PSScriptRoot "..")
$outDirFull = Resolve-Path -Path (Join-Path $rootDir $OutDir) -ErrorAction SilentlyContinue
if (-not $outDirFull) {
  $outDirFull = Join-Path $rootDir $OutDir
}

$appId = if ($env:APP_ID) { $env:APP_ID } else { "com.openspeedtest.app" }
$appName = if ($env:APP_NAME) { $env:APP_NAME } else { "OpenSpeedTest" }
$packageType = if ($env:PACKAGE_TYPE) { $env:PACKAGE_TYPE } else { "debug" }
$androidPlatform = if ($env:ANDROID_PLATFORM) { $env:ANDROID_PLATFORM } else { "android-34" }
$androidBuildTools = if ($env:ANDROID_BUILD_TOOLS) { $env:ANDROID_BUILD_TOOLS } else { "34.0.0" }
$androidSdkRoot = if ($env:ANDROID_SDK_ROOT) { $env:ANDROID_SDK_ROOT } elseif ($env:ANDROID_HOME) { $env:ANDROID_HOME } else { $null }

if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
  throw "Node.js is required (node not found)."
}

if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
  throw "npm is required (npm not found)."
}

$javaHome = if ($env:JAVA_HOME) { $env:JAVA_HOME } else { $null }
if (-not $javaHome) {
  $javac = Get-Command javac -ErrorAction SilentlyContinue
  if ($javac) {
    $javaHome = Split-Path (Split-Path $javac.Source)
    $env:JAVA_HOME = $javaHome
  }
}
if (-not $javaHome) {
  throw "JAVA_HOME is required (Java JDK 17+ not detected)."
}

if (-not $androidSdkRoot) {
  throw "ANDROID_SDK_ROOT (or ANDROID_HOME) is required."
}

$sdkManager = Get-Command sdkmanager -ErrorAction SilentlyContinue
if ($sdkManager) {
  & $sdkManager.Source "platforms;$androidPlatform" "build-tools;$androidBuildTools" | Out-Null
}

$workDir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName())
New-Item -ItemType Directory -Path $workDir | Out-Null

try {
  Write-Host "Creating Cordova project in $workDir"
  npx --yes cordova create "$workDir/app" $appId $appName

  Push-Location "$workDir/app"

  npx --yes cordova platform add android
  npx --yes cordova plugin add cordova-plugin-whitelist

  Remove-Item -Recurse -Force "www/*"
  Copy-Item (Join-Path $rootDir "index.html") -Destination "www/"
  Copy-Item (Join-Path $rootDir "hosted.html") -Destination "www/"
  Copy-Item (Join-Path $rootDir "downloading") -Destination "www/"
  Copy-Item (Join-Path $rootDir "upload") -Destination "www/"
  Copy-Item (Join-Path $rootDir "assets") -Destination "www/" -Recurse

  if ($packageType -eq "release") {
    npx --yes cordova build android --release
  } else {
    npx --yes cordova build android --debug
  }

  $apkPath = Get-ChildItem -Path "platforms/android/app/build/outputs/apk" -Recurse -Filter "*.apk" | Select-Object -First 1
  if (-not $apkPath) {
    throw "APK not found. Check the Cordova build output for errors."
  }

  New-Item -ItemType Directory -Force -Path $outDirFull | Out-Null
  Copy-Item $apkPath.FullName -Destination $outDirFull

  Write-Host "APK generated at: $(Join-Path $outDirFull $apkPath.Name)"
}
finally {
  Pop-Location -ErrorAction SilentlyContinue
  Remove-Item -Recurse -Force $workDir -ErrorAction SilentlyContinue
}
