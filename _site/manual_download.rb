#!/usr/bin/ruby

url = ARGV.shift
system %{ssh rcs@c32.millennium.berkeley.edu "cd /scratch/rcs/youtube; sudo apt-get -y install libav-tools; ../bin/youtube-dl -U; ../bin/youtube-dl -t --audio-quality 0 --audio-format mp3 --extract-audio '#{url}'"}
