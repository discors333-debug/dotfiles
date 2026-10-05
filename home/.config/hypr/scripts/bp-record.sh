#!/usr/bin/env bash
# Screen recorder toggle (SUPER + SHIFT + R): press once to start recording the monitor your mouse is
# on, press again to stop. When it stops, it also saves frames from the video (2 a second) so Claude
# can look through what happened.
#   videos: ~/Videos/bp-debug/rec-<date>.mp4
#   frames: ~/Videos/bp-debug/rec-<date>/frame_0001.jpg ...   (and ~/Videos/bp-debug/latest -> newest)
DIR="$HOME/Videos/bp-debug"
PIDF="$DIR/.recording.pid"
mkdir -p "$DIR"

if [[ -f "$PIDF" ]] && kill -0 "$(cat "$PIDF")" 2>/dev/null; then
  # stop
  PID=$(cat "$PIDF")
  FILE=$(cat "$DIR/.recording.file")
  kill -INT "$PID"
  while kill -0 "$PID" 2>/dev/null; do sleep 0.2; done
  rm -f "$PIDF"
  notify-send -t 3000 "Recording stopped" "Saving frames for Claude…"
  OUT="${FILE%.mp4}"
  mkdir -p "$OUT"
  ffmpeg -loglevel error -y -i "$FILE" -vf "fps=2,scale=1280:-2" -q:v 4 "$OUT/frame_%04d.jpg"
  ln -sfn "$OUT" "$DIR/latest"
  N=$(ls "$OUT" | wc -l)
  notify-send -t 5000 "Recording saved" "$(basename "$FILE") · $N frames ready for Claude"
else
  # start: the monitor the mouse is on
  OUTPUT=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name' | head -1)
  FILE="$DIR/rec-$(date +%Y-%m-%d_%H-%M-%S).mp4"
  echo "$FILE" > "$DIR/.recording.file"
  wf-recorder -o "$OUTPUT" -f "$FILE" -r 30 -c libx264 -p preset=veryfast -p crf=26 >/dev/null 2>&1 &
  echo $! > "$PIDF"
  notify-send -t 2500 "Recording $OUTPUT" "Press SUPER + SHIFT + R again to stop"
fi
