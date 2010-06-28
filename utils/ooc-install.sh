#!/bin/bash

echo "     ___           ___           ___     
    /\  \         /\  \         /\__\    
   /::\  \       /::\  \       /:/  /    
  /:/\:\  \     /:/\:\  \     /:/  /     
 /:/  \:\  \   /:/  \:\  \   /:/  /  ___ 
/:/__/ \:\__\ /:/__/ \:\__\ /:/__/  /\__
\:\  \ /:/  / \:\  \ /:/  / \:\  \ /:/  /
 \:\  /:/  /   \:\  /:/  /   \:\  /:/  / 
  \:\/:/  /     \:\/:/  /     \:\/:/  /  
   \::/  /       \::/  /       \::/  /   
    \/__/         \/__/         \/__/"

echo ""

function intro {
    if [[ ! -x "`which git`" ]]; then
        echo "Sorry, but you need to have git installed for installation to proceed."
        echo ""
        echo "Ubuntu: sudo apt-get install git-core"
        echo "OS X: brew install git"
        echo ""
        exit 1
    else
        if [ ! -x "`which curl`" ] && [ ! -x "`which wget`" ]; then
            echo "Sorry, you need either curl or wget installed."
            echo ""
            echo "Ubuntu: sudo apt-get install curl"
            echo "OS X: brew install wget"
            echo ""
            exit 1
        fi
        echo ""
        read -p "Will install rock head from v0.9.2 source, ok? [y/N] " f
        [[ "$f" == y* ]]
    fi
}

function do_install {
    read -p "Enter installation directory [$HOME/rock]: " f
    if [[ ! -a $f ]]; then
        read -p "$f doesn't exist, create? [y/N] " c
        if [[ $c == y* ]]; then
            mkdir -p "$f"
        else
            exit 1
        fi
    else
        read -p "$f exists, contents will be replaced, are you sure? [y/N] " c
        if [[ ! $c == y* ]]; then
            exit 1
        fi
        rm -rf "$f"
    fi
           
    git clone "http://github.com/nddrylliog/rock.git" "$f"
    export ROCK_DIST="$f"
    cd "$f"
    
    if [ -x "`which curl`" ]; then
        curl -L -\# "http://github.com/downloads/nddrylliog/rock/rock-0.9.2-prealpha1-bootstrap-only.tar.gz2" | tar -zxf -
    elif [ -x "`which wget`" ]; then
        wget --progress=bar "http://github.com/downloads/nddrylliog/rock/rock-0.9.2-prealpha1-bootstrap-only.tar.gz2" -O - | tar -zxf -
    fi
    
    mkdir bin
    make
    
    echo "========================================"
    echo ""
    echo "Finished bootrapping and compiling latest rock."
    echo ""
    echo "Please add the following to your .profile:"
    echo ""
    echo "          export ROCK_DIST=$f"
    echo "          export PATH=$f/bin:\$PATH"
    echo ""
    echo "rock -V should show head and build date (about now)"
    echo "Ex: rock test.ooc (-noclean to leave .c files)"
    echo ""
    echo "Homepage: http://ooc-lang.org"
    echo "IRC: irc.freenode.net #ooc-lang"
    echo ""
    echo "Thank you"
    echo ""
    echo "========================================"
    
}

if intro; then
    echo "Good choice :)"
    echo ""
    do_install
else
    echo ""
    echo ":("
fi
