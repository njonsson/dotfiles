def symlink(force)
  Dir.glob("#{File.dirname __FILE__}/*") do |entry|
    if File.directory?(entry) ||
       (File.expand_path(entry) == File.expand_path(__FILE__))
      next
    end

    dotfile = "#{ENV['HOME']}/.#{File.basename entry}"
    if File.symlink?(dotfile) || File.file?(dotfile)
      if force
        File.delete dotfile
        puts "Deleted #{dotfile}"
      else
        $stderr.puts "#{dotfile} exists!"
        next
      end
    end
    if system("ln -s #{entry} #{dotfile}")
      puts "Linked #{entry} to #{dotfile}"
    end
  end
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
