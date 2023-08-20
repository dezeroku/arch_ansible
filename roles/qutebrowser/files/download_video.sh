#!/bin/sh

url="$QUTE_URL"

echo "message-info 'video-dl: Started downloading $url'" >> "${QUTE_FIFO}"
# shellcheck disable=SC2088
yt-dlp -f 'bestvideo[height<=1080][ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best' --all-subs --convert-subs srt -o '~/Videos/%(title)s.%(ext)s' "${url}" && echo "message-info 'video-dl: Finished downloading $url'" >> "${QUTE_FIFO}" && echo "message-info 'video-dl: Finished downloading $url'" && exit 0
echo "message-error 'video-dl: Error while downloading $url'" >> "${QUTE_FIFO}"
