#!/bin/sh
#
# Install the current build on every attached device — the phone and the
# emulator both, whichever of them adb sees.
#
# The .apkx in the project root is the arm64 split, so it only fits a real
# phone; an x86_64 emulator gets the universal APK the build leaves under
# build/app/outputs/flutter-apk, which carries every ABI.

set -e
cd "$(dirname "$0")"

APK_PATH="build/app/outputs/flutter-apk"

arm64_apk=$(ls -t ./*.apkx 2>/dev/null | head -n1)
universal_apk=$(ls -t "$APK_PATH"/*-universal.apk 2>/dev/null | head -n1)

devices=$(adb devices | awk '/device$/{print $1}')
if [ -z "$devices" ]; then
    echo "No device connected"
    exit 1
fi

for dev in $devices; do
    abi=$(adb -s "$dev" shell getprop ro.product.cpu.abi | tr -d '\r')
    case "$abi" in
        arm64*) src="$arm64_apk" ;;
        *)      src="$universal_apk" ;;
    esac

    if [ -z "$src" ]; then
        echo "--- $dev ($abi): no APK for this ABI, skipped"
        continue
    fi

    # adb wants the .apk extension, and the shipped artifact carries .apkx
    dst="$src"
    case "$src" in
        *.apkx) dst="${src%x}"; cp "$src" "$dst" ;;
    esac

    echo "+++>>> $dev ($abi): $(basename "$src")"
    adb -s "$dev" install -r "$dst"
    [ "$dst" = "$src" ] || rm -f "$dst"
done

sleep 3
