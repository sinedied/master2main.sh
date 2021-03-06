# :robot: master2main.sh

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

> Migrates a git repository from using `master` branch to `main` as default.

## Usage

Open a terminal at the root of the git repository you want to migrate, then run:

```bash
bash <(curl -Ls https://aka.ms/master2main.sh)
```

> Note: https://aka.ms/master2main.sh is a shortlink for https://raw.githubusercontent.com/sinedied/master2main.sh/main/master2main.sh

The migration process is interactive and will prompt you for confirmation before proceeding.

If your repo origin is a GitHub URL, it will set the default branch on GitHub using a personal access token provided via the environment variable `GITHUB_TOKEN`. Your token must have the `repo` access rights.
Follow [these steps](https://docs.github.com/github/authenticating-to-github/creating-a-personal-access-token) to create a personal access token.

### What the script does

1. Search for all references to "master" within your repo and list them, so you can take care of them if needed.
2. Ask for confirmation before proceeding with these steps:
  * `git checkout master`: switch to `master` branch
  * `git pull`: make sure your branch is up-to-date
  * `git branch -m master main`: move branch to `main`.
  * `git push -u origin main` : push the new branch to remote.
  * `git symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main`: switch the local branch HEAD references to `main`.
3. If your repo is linked to a GitHub repository, change the default GitHub branch to `main`.
  * Note: if you have defined [branch protection settings](https://docs.github.com/github/administering-a-repository/configuring-protected-branches), these will **NOT** be migrated, you'll have to take care of it manually. I'm currently looking for a way to also migrate these settings (any help welcome).
  * Read more about GitHub specific challenges [here](https://github.com/github/renaming).
4. Ask for confirmation before proceeding to the final step:
  * `git push origin --delete master`: delete the remote `master` branch.

And because you should never trust any random script you found on the internet, you can always check the [script source](master2main.sh) to see the details.

## Contributing

If you have an idea to improve this script, you're welcome to propose a [pull request](https://github.com/sinedied/master2main.sh/pulls).
