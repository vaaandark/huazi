#!/usr/bin/env bash
# 免 root 安装 Flutter / JDK / Android SDK 到 ~/opt 与 ~/Android
# 用法: bash tool/setup-toolchain.sh
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-3.50.1}"
JDK_DIR="$HOME/opt/jdk-17"
FLUTTER_DIR="$HOME/opt/flutter"
ANDROID_HOME="$HOME/Android/Sdk"
DL="$HOME/opt/downloads"

mkdir -p "$HOME/opt" "$DL" "$ANDROID_HOME"

log() { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }

# ---------- JDK 17 ----------
if [ ! -x "$JDK_DIR/bin/java" ]; then
  log "下载 JDK 17 (Temurin)"
  curl -fL --retry 3 -o "$DL/jdk17.tar.gz" \
    "https://api.adoptium.net/v3/binary/latest/17/ga/linux/x64/jdk/hotspot/normal/eclipse"
  mkdir -p "$JDK_DIR"
  tar -xzf "$DL/jdk17.tar.gz" -C "$JDK_DIR" --strip-components=1
fi
export JAVA_HOME="$JDK_DIR"
export PATH="$JAVA_HOME/bin:$PATH"
java -version

# ---------- Android cmdline-tools ----------
SDKMANAGER="$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager"
if [ ! -x "$SDKMANAGER" ]; then
  log "下载 Android cmdline-tools"
  CT_VER="13114758"
  curl -fL --retry 3 -o "$DL/cmdline-tools.zip" \
    "https://dl.google.com/android/repository/commandlinetools-linux-${CT_VER}_latest.zip"
  rm -rf "$ANDROID_HOME/cmdline-tools"
  mkdir -p "$ANDROID_HOME/cmdline-tools"
  unzip -q "$DL/cmdline-tools.zip" -d "$ANDROID_HOME/cmdline-tools"
  mv "$ANDROID_HOME/cmdline-tools/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest"
fi

log "接受 Android 许可并安装 platform/build-tools"
yes | "$SDKMANAGER" --sdk_root="$ANDROID_HOME" --licenses >/dev/null 2>&1 || true
"$SDKMANAGER" --sdk_root="$ANDROID_HOME" "platform-tools" "platforms;android-36" "build-tools;36.0.0" \
  || "$SDKMANAGER" --sdk_root="$ANDROID_HOME" "platform-tools" "platforms;android-35" "build-tools;35.0.0"

# ---------- Flutter ----------
if [ ! -x "$FLUTTER_DIR/bin/flutter" ]; then
  log "下载 Flutter $FLUTTER_VERSION"
  curl -fL --retry 3 -o "$DL/flutter.tar.xz" \
    "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
  tar -xJf "$DL/flutter.tar.xz" -C "$HOME/opt"
fi
export PATH="$FLUTTER_DIR/bin:$PATH"
git config --global --add safe.directory "$FLUTTER_DIR" 2>/dev/null || true

log "配置 Flutter"
flutter config --no-analytics >/dev/null 2>&1 || true
flutter config --android-sdk "$ANDROID_HOME" >/dev/null
flutter --version

log "完成。把下面写进 ~/.bashrc 或 ~/.zshrc："
cat <<EOF
export JAVA_HOME="$JDK_DIR"
export ANDROID_HOME="$ANDROID_HOME"
export PATH="\$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$FLUTTER_DIR/bin:\$PATH"
EOF
