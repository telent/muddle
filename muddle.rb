#!/usr/bin/env ruby
require 'pathname'
require 'open3'

class Tarfile
  HEADER_PACK_FORMAT = "a100a8a8a8a12a12a7aaa100a6a2a32a32a8a8a155"
  HEADER_UNPACK_FORMAT = "Z100A8A8A8A12A12A8aZ100A6A2Z32Z32A8A8Z155"
  class Header < Struct.new(:name, :mode, :uid, :gid, :size, :mtime, :checksum,
                            :typeflag, :linkname, :magic, :version,
                            :uname, :gname, :devmajor, :devminor, :prefix)
    def self.new_from_stream(stream)
      data = stream.read(512)
      self.new(*data.unpack(HEADER_UNPACK_FORMAT))
    end
  end
  def initialize(stream)
    @stream=stream
  end
  def each_file
    while ! @stream.eof?
      header = Header.new_from_stream(@stream)
      next if header.size.empty?
      len = header.size.oct
      data = @stream.read(len)
      yield(header, data)
      @stream.read((512 - len) % 512)
    end
  end
end

class Maildir
  attr_reader :directory
  def initialize(directory, hostname=nil)
    if hostname.nil? && directory.index(':')
      @hostname, @directory = directory.split(':')
    else
      @hostname = hostname
      @directory = directory
    end
    @files={}
  end
  def cmd(command)
    @hostname ? "/usr/bin/ssh #{@hostname} #{command}" : command
  end
  def files
    if @files.empty?
      find_cmd = cmd("find")
      IO.popen("#{find_cmd} #{@directory}/new #{@directory}/cur -maxdepth 1 -print0").read.split("\0").each {|f|
        dir,name = Pathname.new(f).split
        base, ext = name.to_s.split(/:/)
        @files[base] = [f, ext]
      }
    end
    @files
  end
  def stream_files(names,&blk)
    Open3.popen2(cmd("cpio -o --format=tar")) do |stdin,stdout,p|
      Kernel.fork do
        names.each do |n|
          IO.select(nil,[stdin])
          warn n if $verbose
          stdin.puts n
        end
        stdin.flush
      end
      stdin.close
      Tarfile.new(stdout).each_file(&blk)
      p.value
    end
  end
end

$verbose=ARGV.delete('--verbose')

unless ARGV.length == 2
  warn "Usage: #{$0} [--verbose] remotehost:/remote/path /local/path"
  exit 1
end

r = Maildir.new(ARGV[0])
l = Maildir.new(ARGV[1])
new_messages = r.files.keys - l.files.keys

warn [:lll,l.directory,r.directory,$verbose]
warn [r.files.keys.count, l.files.keys.count, new_messages.count]


r.stream_files(new_messages.map {|name| r.files[name].first}) do |header, data|
  name = Pathname.new(header.name)
  basename = name.basename.to_s
  unless basename.index(":2,")
    basename = basename + ":2,"
  end
  tmp_name = [l.directory, "tmp", basename].join("/")
  final_name = [l.directory, "cur", basename].join("/")
  File.open(tmp_name, "w") {|o| o.write(data) }
  File.rename(tmp_name, final_name)
  warn final_name if $verbose
end
