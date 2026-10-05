#!/usr/bin/env python3
# Native messaging host for the "Wallpaper Theme" Firefox add-on: sends the theme that
# ~/.config/mango/apply-theme.sh writes, then again whenever the file changes
import json, os, select, struct, sys

path = os.path.expanduser("~/.cache/wallpaper-theme-firefox.json")
sent = None
while True:
    try:
        mtime = os.stat(path).st_mtime
        if mtime != sent:
            data = open(path, "rb").read()
            json.loads(data)  # skip a half-written file; it's retried next second
            sys.stdout.buffer.write(struct.pack("@I", len(data)) + data)
            sys.stdout.buffer.flush()
            sent = mtime
    except (OSError, ValueError):
        pass
    # Firefox closes stdin when the add-on disconnects
    if select.select([sys.stdin], [], [], 1)[0] and not sys.stdin.buffer.read1(4096):
        break
