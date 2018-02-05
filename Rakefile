require 'erb'

DOTFILES_SENTINEL_FILENAME = '.DOTFILES'
HOME = ENV['HOME']

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

def generate_or_symlink(source)
  if erb?(source)
    source_basename = File.basename(source, File.extname(source))
    target = yield("#{File.dirname source}/#{source_basename}")
    return unless delete_if_exists(target)
    File.open target, 'w' do |f|
      f.write ERB.new(File.read(source)).result
    end
    success "Generated #{short_name target} from #{short_name source}"
  else
    target = yield(source)
    return unless delete_if_exists(target)
    begin
      File.symlink source, target
    rescue NotImplementedError
      warning 'Symlinks are not supported on your system'
      return unless system("cp #{source} #{target}")
      success "Copied to #{short_name target} from #{short_name source}"
    else
      success "Symlinked #{short_name target} to #{short_name source}"
    end
  end
end

def info(message)
  puts "*** #{message}"
end

def relative_name(path)
  File.expand_path(path).sub(
    /^#{Regexp.escape File.expand_path(File.dirname(__FILE__))}\/?/,
    ''
  )
end

def short_name(path)
  relative_name(path).sub(/^#{Regexp.escape HOME}/, '~')
    .sub(/^([^~])/, './\\1')
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
  task :all => [:bin, :dotfiles, :fonts]

  namespace :all do
    desc 'Perform all setup tasks, replacing files as necessary'
    task :force => [:set_force_option, 'set_up:all']
  end

  desc 'Generate or symlink scripts into ~/bin'
  task :bin do
    target_dir = "#{HOME}/bin"
    fail unless system("mkdir -p #{target_dir}")

    pattern = "#{File.expand_path File.dirname(__FILE__)}/resources/*.{bash,rb,sh}"
    Dir.glob(pattern) do |script|
      generate_or_symlink script do |source|
        source_basename = File.basename(source, File.extname(source))
        "#{HOME}/bin/#{source_basename}"
      end
    end
  end

  namespace :bin do
    desc 'Set up scripts, replacing files as necessary'
    task :force => [:set_force_option, 'set_up:bin']
  end

  desc 'Generate or symlink dotfiles into ~'
  task :dotfiles => :update_git_submodules do
    non_dotfiles_dirs_relative = []
    Dir.glob("#{File.expand_path File.dirname(__FILE__)}/**/*") do |entry|
      relative_entry = relative_name(entry)
      next if non_dotfiles_dirs_relative.find do |relative_dir|
        relative_entry.start_with?("#{relative_dir}/")
      end

      if (File.directory?(entry) && !File.exist?("#{entry}/#{DOTFILES_SENTINEL_FILENAME}"))
        warning "Ignoring #{short_name entry}/ because it does not contain a #{DOTFILES_SENTINEL_FILENAME} file"
        non_dotfiles_dirs_relative  << relative_entry
        next
      end

      if (File.expand_path(entry) == File.expand_path(__FILE__)) ||
         (File.extname(entry).downcase == '.markdown')
        next
      end

      if File.directory?(entry)
        system("mkdir -p #{HOME}/.#{relative_entry}")
        next
      end

      generate_or_symlink entry do |source|
        source_basename = File.basename(source, File.extname(source))
        "#{HOME}/.#{source_basename}"
      end
    end

    target_dir = "#{ENV['HOME']}/.config"
    fail unless system("mkdir -p #{target_dir}")
    generate_or_symlink File.expand_path('../nvim', __FILE__) do |source|
      "#{target_dir}/#{File.basename source}"
    end
  end

  namespace :dotfiles do
    desc 'Set up dotfiles, replacing files as necessary'
    task :force => [:set_force_option, 'set_up:dotfiles']
  end

  desc 'Copy fonts into ~/Library/Fonts'
  task :fonts do
    target_dir = "#{HOME}/Library/Fonts"
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
