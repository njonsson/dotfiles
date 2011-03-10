require 'erb'

def generate_or_symlink(file, options={})
  extname = File.extname(file)
  is_erb = (extname =~ /^\.erb/i)
  basename = File.basename(file, (is_erb ? extname : ''))
  dotfile = "#{ENV['HOME']}/.#{basename}"
  dotfile_short = "~/.#{basename}"
  if File.exist?(dotfile) || File.symlink?(dotfile)
    if options[:force]
      File.delete dotfile
      info "Deleted #{dotfile_short}"
    else
      warning "Not replacing existing #{dotfile_short}"
      return
    end
  end

  if is_erb
    File.open dotfile, 'w' do |f|
      f.write ERB.new(File.read(file)).result
    end
    success "Generated #{dotfile_short} from #{File.basename(file)}"
  else
    begin
      File.symlink file, dotfile
    rescue NotImplementedError
      warning 'Symlinks are not supported on your system'
      File.open dotfile, 'w' do |f|
        f.write File.read(file)
      end
      success "Copied to #{dotfile_short} from #{basename}"
    else
      success "Symlinked #{dotfile_short} to #{basename}"
    end
  end
end

def info(message)
  puts "*** #{message}"
end

def setup(options={})
  Dir.glob("#{File.dirname __FILE__}/*") do |entry|
    if File.directory?(entry)                                  ||
       (File.expand_path(entry) == File.expand_path(__FILE__)) ||
       (File.extname(entry).downcase == '.markdown')
      next
    end

    generate_or_symlink entry, options
  end
end

def success(message)
  puts "\x1b[32m*** #{message}\x1b[0m"
end

def warning(message)
  puts "\x1b[31m*** #{message}\x1b[0m"
end

desc "Create symbolic links and generate files in #{ENV['HOME']} without overwriting existing files"
task :setup do
  setup
end

desc "Create symbolic links and generate files in #{ENV['HOME']} without overwriting existing files"
task '' => :setup

namespace :setup do
  desc "Delete and recreate symbolic links and generated files in #{ENV['HOME']}"
  task :force do
    setup :force => true
  end
end

task :default => :setup
