def info(message)
  puts "*** #{message}"
end

def success(message)
  puts "\x1b[32m*** #{message}\x1b[0m"
end

def symlink(force)
  Dir.glob("#{File.dirname __FILE__}/*") do |entry|
    if File.directory?(entry)                                  ||
       (File.expand_path(entry) == File.expand_path(__FILE__)) ||
       (File.extname(entry).downcase == '.markdown')
      next
    end

    basename = File.basename(entry)
    dotfile = "#{ENV['HOME']}/.#{basename}"
    dotfile_short = "~/.#{basename}"
    if File.symlink?(dotfile) || File.file?(dotfile)
      if force
        File.delete dotfile
        info "Deleted #{dotfile_short}"
      else
        warning "Not replacing existing #{dotfile_short}"
        next
      end
    end
    if system("ln -s #{entry} #{dotfile}")
      success "Symlinked #{dotfile_short} to #{basename}"
    end
  end
end

def warning(message)
  puts "\x1b[31m*** #{message}\x1b[0m"
end

desc "Create symbolic links in #{ENV['HOME']} without overwriting existing files"
task :symlink do
  symlink false
end

desc "Create symbolic links in #{ENV['HOME']} without overwriting existing files"
task '' => :symlink

namespace :symlink do
  desc "Delete and recreate symbolic links in #{ENV['HOME']}"
  task :force do
    symlink true
  end
end

task :default => :symlink
