require 'erb'

def delete_if_exists(file)
  if File.exist?(file) || File.symlink?(file)
    if @force
      File.delete file
      info "Deleted #{short_name file}"
    else
      warning "Not replacing existing #{short_name file}"
      return false
    end
  end
  true
end

def erb?(file)
  !(file !~ /\.erb$/i)
end

def generate_or_symlink(file, dotfile=nil)
  basename = File.basename(file, (erb?(file) ? File.extname(file) : ''))
  dotfile ||= "#{ENV['HOME']}/.#{basename}"
  return unless delete_if_exists(dotfile)

  if erb?(file)
    File.open dotfile, 'w' do |f|
      f.write ERB.new(File.read(file)).result
    end
    success "Generated #{short_name dotfile} from #{short_name file}"
  else
    begin
      File.symlink file, dotfile
    rescue NotImplementedError
      warning 'Symlinks are not supported on your system'
      return unless system("cp #{file} #{dotfile}")
      success "Copied to #{short_name dotfile} from #{short_name file}"
    else
      success "Symlinked #{short_name dotfile} to #{short_name file}"
    end
  end
end

def info(message)
  puts "*** #{message}"
end

def short_name(path)
  File.expand_path(path).gsub(/^#{Regexp.escape File.expand_path(File.dirname(__FILE__))}\/?/, '').
                         gsub(/^#{Regexp.escape ENV['HOME']}/,                                 '~')
end

def success(message)
  puts "\x1b[32m*** #{message}\x1b[0m"
end

def warning(message)
  puts "\x1b[31m*** #{message}\x1b[0m"
end

task :default => 'set_up:all'

desc 'Perform all setup tasks without overwriting existing files'
task '' => 'set_up:all'

task :set_force_option do
  @force = true
end

desc 'Perform all setup tasks without overwriting existing files'
task :set_up => 'set_up:all'

namespace :set_up do
  desc 'Perform all setup tasks without overwriting existing files'
  task :all => [:dotfiles, :fonts]

  namespace :all do
    desc 'Perform all setup tasks, replacing files as necessary'
    task :force => [:set_force_option, 'set_up:all']
  end

  desc "Set up dotfiles in #{ENV['HOME']}"
  task :dotfiles => :update_git_submodules do
    Dir.glob("#{File.dirname __FILE__}/*") do |entry|
      if File.directory?(entry)                                  ||
         (File.expand_path(entry) == File.expand_path(__FILE__)) ||
         (File.extname(entry).downcase == '.markdown')
        next
      end

      generate_or_symlink entry, nil
    end
  end

  namespace :dotfiles do
    desc "Delete and recreate dotfiles in #{ENV['HOME']}"
    task :force => [:set_force_option, 'set_up:dotfiles']
  end

  desc 'Set up fonts'
  task :fonts do
    target_dir = "#{ENV['HOME']}/Library/Fonts"
    fail unless system("mkdir -p #{target_dir}")

    pattern = "#{File.expand_path File.dirname(__FILE__)}/resources/*.[ot]tf"
    Dir.glob(pattern) do |font|
      next unless File.file?(font)

      target = "#{target_dir}/#{File.basename font}"
      next unless delete_if_exists(target)

      return unless system("cp #{font} #{target}")
      success "Copied to #{short_name target} from #{short_name font}"
    end
  end

  namespace :fonts do
    desc 'Set up fonts, replacing files as necessary'
    task :force => [:set_force_option, 'set_up:fonts']
  end
end

task :update_git_submodules do
  fail unless system('git submodule update --init')
end
