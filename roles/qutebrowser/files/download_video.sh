#!/bin/sh

url="$QUTE_URL"

echo "message-info 'video-dl: Started downloading $url'" >> $QUTE_FIFO
youtube-dl -f 'best[height<=?720p]' --all-subs --convert-subs srt -o '~/Video/%(title)s.%(ext)s' $url && echo "message-info 'video-dl: Finished downloading $url'" >> $QUTE_FIFO && exit 0
echo "message-error 'video-dl: Error while downloading $url'" >> $QUTE_FIFO
