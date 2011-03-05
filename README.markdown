Nils's dotfiles
===============

This repository contains my OS X shell configuration.

1. Clone this repository.
2. `cd` into it.
3. Type `rake --tasks`.

You should see the following, where _~_ is the path to your home directory:

    rake                # Create symbolic links in ~ without overwriting existing files
    rake symlink        # Create symbolic links in ~ without overwriting existing files
    rake symlink:force  # Delete and recreate symbolic links in ~

When you type `rake`, all the files in the root of this repository† are
symbolically linked into your home directory, with a dot prepended to the
filename of each link. For example, the _gemrc_ in this repository gets
symbolically linked to _~/.gemrc_ (unless there is already a _.gemrc_ in your
home directory).

Leaving off the dots in these files makes them more convenient for me to edit
and manage, and it allows me to ignore dotfiles that pertain to this repository
rather than to my home directory.

----------------------------------------------------------------

† Note: _Rakefile_ and _*.markdown_ are not treated as dotfiles.
