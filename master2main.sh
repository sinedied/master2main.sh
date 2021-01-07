#!/bin/bash

##############################################################################
# Usage: ./master2main.sh [-y]
# Options:
#   -y  do not prompt for confirmation before proceeding to migration
#
# Migrates a git repository from using "master" branch to "main" as default.
#
# Before migration, it searches for all references to "master" within your
# repo, allowing you to take care of them if any before proceeding with the
# migration.
#
# If your repo origin is a GitHub URL, it also sets the default branch on 
# GitHub using a personal access token provided via the environment variable 
# GITHUB_TOKEN. Your token must have the "repo" access rights.
# See https://docs.github.com/github/authenticating-to-github/creating-a-personal-access-token
# for learning how to create a personal access token.
#
# This script must be run at the root of a git repository.
#
# You can execute this script directly from the web with:
# bash <(curl -Ls https://aka.ms/master2main.sh)
##############################################################################

set -e

COLOR_RST="$(tput sgr0)"
COLOR_RED="$(tput setaf 1)"
COLOR_GREEN="$(tput setaf 2)"
COLOR_YELLOW="$(tput setaf 3)"
UNDERLINE="$(tput smul)"

# Skip confirmation option
if [[ $1 == "-y" ]]; then
  SKIP_CONFIRMATION=1
fi

# Check if we are in a git repo root
if [[ ! -d ".git" ]]; then
  echo "${COLOR_RED}Not a git repository or you're not running this script on the repo root!${COLOR_RST}"
  echo
  exit 1
fi

REPO_URL="$(git config --get remote.origin.url)"

# Check if it's a GitHub repo
if [[ $REPO_URL == *"github.com"* ]]; then
  IS_GITHUB=1
fi

# Parse GitHub repo name and owner
if [[ IS_GITHUB ]]; then
  PARSE_GITHUB_RE="^(https|git)(:\/\/|@)([^\/:]+)[\/:]([^\/:]+)\/(.+).git$"

  if [[ $REPO_URL =~ $PARSE_GITHUB_RE ]]; then    
    OWNER=${BASH_REMATCH[4]}
    REPO=${BASH_REMATCH[5]}
    GITHUB_API="https://api.github.com/repos/${OWNER}/${REPO}"
    echo "Found GitHub repo: $OWNER/$REPO"
    echo
  else
    echo "${COLOR_RED}Cannot parse GitHub repo URL: ${REPO_URL}${COLOR_RST}"
    echo
    exit 1
  fi

  # Check GitHub access token is set
  if [[ -z "$GITHUB_TOKEN" ]]; then
    echo "${COLOR_YELLOW}GITHUB_TOKEN environment variable not set!${COLOR_RST}"
    echo "${COLOR_YELLOW}Without it, the script won't be able to switch the default branch on GitHub.${COLOR_RST}"
    echo
    exit 1
  fi
fi

# Check for existing references of "master" within repo
echo "$COLOR_GREEN** Listing references to \"master\" in this repo **$COLOR_RST"
echo
set +e
grep --color -rnw . -e master --exclude-dir node_modules --exclude-dir .git

if [[ $? -eq 0 ]]; then
  echo
  echo "${COLOR_YELLOW}Some references to \"master\" were found in your repo.${COLOR_RST}"
  echo "${COLOR_YELLOW}You might want to check if these need changes before proceeding to migration.${COLOR_RST}"
else
  echo "No references found, all clear!"
fi

set -e
echo

# Confirm migration
if [[ ! $SKIP_CONFIRMATION ]]; then
  read -p "${COLOR_YELLOW}Proceed with migration? (y/N) ${COLOR_RST}" -n 1 -r
  echo
  echo

  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

# That's it! Perform the branch migration
echo "${COLOR_GREEN}** Migrating \"master\" branch to \"main\" **${COLOR_RST}"
echo
set -x

git checkout master
git pull
git branch -m master main
git push -u origin main
git symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main

set +x
echo
echo "Done."
echo

# Change the default branch also on GitHub, if needed
if [[ IS_GITHUB ]]; then
  echo "${COLOR_GREEN}** Changing GitHub default branch to \"main\" **${COLOR_RST}"
  echo
  curl -H "Authorization: token $GITHUB_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"${REPO}\",\"default_branch\":\"main\"}" \
    -X PATCH -L -s $GITHUB_API > /dev/null
  echo "Done."
  echo

  # Check if master branch is protected
  PROTECTED=$(curl $GITHUB_API/branches/master | grep -Eo '"protected":(.*)')

  if [[ $PROTECTED == *"true"* ]]; then
    echo "${COLOR_YELLOW}There are protection rules set on master branch.${COLOR_RST}"
    echo "${COLOR_YELLOW}Open ${UNDERLINE}https://github.com/${OWNER}/${REPO}/settings/branches${COLOR_RST}${COLOR_YELLOW} to edit them.${COLOR_RST}"
    echo
    read -s -n 1 -p "Press enter to continue."
    echo
    echo
  fi
fi

# Confirm master branch deletion on remote
if [[ ! $SKIP_CONFIRMATION ]]; then
  read -p "${COLOR_YELLOW}This is the last step, delete \"master\" branch on remote? (y/N) ${COLOR_RST}" -n 1 -r
  echo
  echo

  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "${COLOR_GREEN}** Deleting \"master\" branch on remote **${COLOR_RST}"
    echo
    set +x

    git push origin --delete master

    set -x
  else
    echo
    echo "Once you've checked everything is fine on your end, you can run this command"
    echo "to remove the \"master\" branch on remote:"
    echo
    echo "git push origin --delete master"
  fi
fi

echo
echo "Migration complete."
echo
