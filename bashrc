
# Add git branch if its present to PS1
parse_git_branch() {
  git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}

PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\[\033[33m\]$(parse_git_branch)\[\033[0m\]\$ '

# More alias
alias so='source ~/.bashrc'
alias studio='studio.sh &'
alias clr='clear'
alias cls='clear'
alias gitdiff='git difftool -d'
