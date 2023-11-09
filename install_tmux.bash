#!/usr/bin/env bash
# This script will install latest tmux, why not?


script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

usage() {
  cat <<EOF
  Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-r] [-d]
  Script description here.
  Available options:
  -h, --help          Print this help and exit
  -a, --auto          Set true to auto select the last tag in the list
  -d, --depedencies   Set false to not install depedencies, true by default
EOF
exit
}

setup_colors() {
  if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
    NOFORMAT='\033[0m' RED='\033[0;31m' GREEN='\033[0;32m' ORANGE='\033[0;33m' BLUE='\033[0;34m' PURPLE='\033[0;35m' CYAN='\033[0;36m' YELLOW='\033[1;33m'
  else
    NOFORMAT='' RED='' GREEN='' ORANGE='' BLUE='' PURPLE='' CYAN='' YELLOW=''
  fi
}

msg() {
  echo >&2 -e "${1-}"
}

die() {
  local msg=$1
  local code=${2-1} # default exit status 1
  msg "$msg"
  exit "$code"
}

parse_params() {
  # default values of variables set from params
  AUTO_SELECT="false"
  BRANCH=""
  DEPS="true"
  TMUX_DIR="$HOME/reference/tmux.git"

  while test $# -gt 0; do
    case $1 in
      -h | --help) usage ;;
      -a | --auto)
        shift
        if [[ $1 == "true" || $1 == "false" ]]
        then
          AUTO_SELECT=$1
        else
          die "-a only accepts true or false."
        fi
        ;;
      -d | --depedencies)
        shift
        if [[ $1 == "true" || $1 == "false" ]]
        then
          DEPS=$1
        else
          die "-d only accepts true or false."
        fi
        ;;
      -?*) die "Unknown option: $1" ;;
      *) break ;;
    esac
    shift
  done

  return 0
}

parse_params "$@"
setup_colors 

# Get current dir path
CURRENT_DIR="$(pwd)"

# Install build depedencies for tmux
if [[ $DEPS == "true" ]]
then
  echo "Installing depedencies for building tmux..."
  sudo apt-get install bison byacc -y
fi

# Checks if tmux directory already exists
if [ ! -d "$TMUX_DIR" ]
then
  mkdir -p $HOME/reference
  cd $HOME/reference
  git clone --bare https://github.com/tmux/tmux.git
  cd $TMUX_DIR
  git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
  git fetch
else
  cd $TMUX_DIR
  git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
  git fetch
fi

if [[ $AUTO_SELECT == "false" ]]
then
  # Display all available tags
  echo "Available tags:"
  declare -a arr
  i=0

    # Make tags name into an array
    tags=$(git for-each-ref refs  --format='%(refname)' | grep tags | cut -d/ -f3)
    for tag in $tags
    do
      arr[$i]=$tag
      let "i+=1"
    done

    # Loop through name array
    let "i-=1"
    for j in $(seq 0 $i)
    do
      echo $j")" ${arr[$j]}
    done

    # Obtain tag name
    read -p "TMUX Branch to be used: " BRANCH
    if [ -d  ${arr[$BRANCH]} ]
    then
      cd ${arr[$BRANCH]}
    else
      git worktree add ${arr[$BRANCH]} ${arr[$BRANCH]}
      cd ${arr[$BRANCH]}
    fi

    ./autogen.sh
    ./configure && make
    # sudo make install # Still not brave enough to make this step...

    echo -e $GREEN"Successfully installed tmux, ENJOY! :)"$NOFORMAT

  else
    declare -a arr
    i=0

    # Make tags name into an array
    tags=$(git for-each-ref refs  --format='%(refname)' | grep tags | cut -d/ -f3)
    for tag in $tags
    do
      arr[$i]=$tag
      let "i+=1"
    done
    let "i-=1"

    if [ -d  ${arr[$i]} ]
    then
      cd ${arr[$i]} 
    else
      git worktree add ${arr[$i]} ${arr[$i]}
      cd ${arr[$i]}
    fi

    ./autogen.sh
    ./configure && make
    # sudo make install # Still not brave enough to make this step...

    echo -e $GREEN"Successfully installed tmux, ENJOY!:)\n"$NOFORMAT
fi

