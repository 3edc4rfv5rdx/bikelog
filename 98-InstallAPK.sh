#!/bin/sh


src=$(ls -t Bike*.apkx | head -n1)
dst="${src%x}"
cp "$src" "$dst"
echo "+++>>> $dst"
adb -s RFGL205J57N install -r $dst
rm -f "$dst"

sleep 3
