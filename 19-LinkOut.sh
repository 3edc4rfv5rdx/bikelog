#!/usr/bin/env bash
#
# Put the files of the newest build into OUT/ as links under their own
# names, and sweep everything else out of that folder:
#
#   OUT/bikelog-<version>-<build>-arm64-v8a.apk
#   OUT/bikelog-<version>-<build>-universal.apk
#   OUT/bikelog-<version>-<build>-x86_64.AppImage   (only if one was built)
#
# One place to copy the build from, instead of paths deep inside build/.
# The links are hard ones: the entry here is the file itself, so copying it
# elsewhere copies a build and not a dangling path, and the pruning of old APKs
# inside build/ leaves it whole. The name carries the version and the build
# number, so the listing says which build it is. Nothing is built here:
# 00-MakeAll.sh runs the same steps after a build, and this is for picking up a
# build that already exists.
#
cd "$(dirname "$0")"

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    sed -n '2,17p' "$0"
    exit 0
fi

MISSING=""
# An array, not a string of names. The artifact name used to come from the
# Android label, and a label with a space in it turned the membership test below
# into a match on halves of two different names: the file just linked then failed
# to recognise itself and the sweep deleted it. The name comes out of pubspec.yaml
# now and carries no spaces, but a list of names is still a list, not one string
# with separators in it.
LINKED=()

newest_of() { ls -t "$@" 2>/dev/null | head -1; }

link_file() { # link_file <file>
    local name
    name=$(basename "$1")
    mkdir -p OUT
    ln -f "$1" "OUT/$name"
    LINKED+=("$name")
    echo "OUT/$name"
}

link_latest() { # link_latest <candidate files...>
    local newest
    newest=$(newest_of "$@")
    if [ -z "$newest" ] || [ ! -f "$newest" ]; then
        echo ">>> nothing to link into OUT"
        MISSING="yes"
        return 0
    fi
    link_file "$newest"
}

# The desktop build is a step of its own and is off by default, so a missing
# image is not an incomplete set: link one when it is there, say nothing when it
# is not. Marking it missing would stop the sweep below on every ordinary run.
link_optional() { # link_optional <candidate files...>
    local newest
    newest=$(newest_of "$@")
    [ -n "$newest" ] && [ -f "$newest" ] && link_file "$newest"
    return 0
}

link_latest build/app/outputs/flutter-apk/*arm64-v8a*.apk
# The fat APK, for a device whose ABI is none of the splits built here.
link_latest build/app/outputs/flutter-apk/*-universal.apk
# The Linux build, when 14-MakeAppImage.sh made one.
link_optional build/linux/*-x86_64.AppImage

# Everything else goes: the previous build's names, an ABI no longer built, a
# copy left behind. Only files and links — a directory somebody made here is
# not ours to remove.
#
# And only when every artifact was linked. A run that could not find one of them
# used to sweep anyway, which deleted the previous good build and reported the
# failure afterwards: OUT/ then held half a release. Nothing is removed until
# there is a full set to replace it with.
if [ -z "$MISSING" ] && [ -d OUT ]; then
    for entry in OUT/* ; do
        [ -d "$entry" ] && continue
        [ -e "$entry" ] || [ -L "$entry" ] || continue
        name=$(basename "$entry")
        keep=""
        for linked in ${LINKED+"${LINKED[@]}"}; do
            [ "$name" = "$linked" ] && { keep=yes; break; }
        done
        [ -n "$keep" ] && continue
        rm -f "$entry"
    done
fi

if [ -n "$MISSING" ]; then
    echo ">>> incomplete set: OUT left as it was"
    exit 1
fi
exit 0
