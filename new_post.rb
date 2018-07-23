#!/usr/bin/ruby

posts_dir       = "_posts"    # directory for blog files
new_post_ext    = "markdown"  # default new post file extension when using the new_post task

def extract_url(filename)
  File.foreach(filename) do |line|
    if line =~ /permalink/
      url = line.split[1]
      return url
    end
  end
end

def parse_youtube_video_id(filename)
  require 'uri'
  url = extract_url(filename)
  video_id = nil
  if url =~ /youtube.com/
    video_id = URI(url).query.split("v=")[1]
  elsif url =~ /youtu.be/
    video_id = URI(url).query.split("/")[-1]
  end
  return video_id
end

def upload_post(title)
  mkdir_p "#{posts_dir}"
  filename = "#{posts_dir}/#{Time.now.strftime('%Y-%m-%d')}-#{title.to_url}.#{new_post_ext}"
  if File.exist?(filename)
    abort("rake aborted!") if ask("#{filename} already exists. Do you want to overwrite?", ['y', 'n']) == 'n'
  end
  puts "Creating new post: #{filename}"
  open(filename, 'w') do |post|
    post.puts "---"
    post.puts "layout: post"
    post.puts "permalink: "
    post.puts "title: \"#{title.gsub(/&/,'&amp;')}\""
    post.puts "date: #{Time.now.strftime('%Y-%m-%d %H:%M:%S %z')}"
    post.puts "comments: true"
    post.puts "categories: "
    post.puts "---"
  end
  system "vim #{filename}"
  system "git add _posts"
  system "git commit -m 'new song'"
  system "git push"
  url = extract_url filename
  if url =~ /youtube/i or url =~ /youtu.be/i
    video_id = parse_youtube_video_id filename
    system "youtube_api/add_video.py --video_id=#{video_id}"
    system %{ssh rcs@c32.millennium.berkeley.edu "cd /scratch/rcs/youtube; sudo apt-get -y install libav-tools; ../bin/youtube-dl -U; ../bin/youtube-dl -t --audio-quality 0 --audio-format mp3 --extract-audio '#{url}'"}
    Dir.chdir "/Users/cs/Music/youtube" do
      system "rsync -v rcs@c32.millennium.berkeley.edu:/scratch/rcs/youtube/* ."
    end
  end
end

if __FILE__ == $0
  if ARGV.empty?
    raise ArgumentError.new("Expected: #{$0} <title>"
  end
  upload_post(ARGV.shift)
end
