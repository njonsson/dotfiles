Nils's dotfiles
===============

This repository contains my OS X shell configuration.

1. Clone this repository.
2. `cd` into it.
3. Type `rake --tasks`.

You should see the following, where _~_ is the path to your home directory:

    rake                        # Perform all setup tasks without overwriting existing files
    rake set_up                 # Perform all setup tasks without overwriting existing files
    rake set_up:all             # Perform all setup tasks without overwriting existing files
    rake set_up:all:force       # Perform all setup tasks, replacing files as necessary
    rake set_up:dotfiles        # Set up dotfiles in ~
    rake set_up:dotfiles:force  # Delete and recreate dotfiles in ~
    rake set_up:fonts           # Set up fonts
    rake set_up:fonts:force     # Set up fonts, replacing files as necessary

When you type `rake`, all the files in the root of this repository† are either
symbolically linked or generated into your home directory, with a dot prepended
to the filename of each link. For example, the _gemrc_ in this repository gets
symbolically linked to _~/.gemrc_ (unless there is already a _.gemrc_ in your
home directory). The _vimrc.local.erb_ in this repository is used to generate
_~/.vimrc.local_ (unless there is already a _.vimrc.local_ in your home
directory).

Leaving off the dots in these files makes them more convenient for me to edit
and manage, and it allows me to ignore dotfiles that pertain to this repository
rather than to my home directory.

Credits
-------

The
[Mensch](http://robey.lag.net/2010/06/21/mensch-font.html "Mensch, A Coding Font")
font was created by [Robey Pointer](http://robey.lag.net).

The [Solarized](http://ethanschoonover.com/solarized) color schemes were created
by [Ethan Schoonover](http://ethanschoonover.com).

----------------------------------------------------------------

† Note: _Rakefile_ and _*.markdown_ are not treated as dotfiles.
