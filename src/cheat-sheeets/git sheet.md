To disable TLS/SSL verification for a single git command
try passing -c to git with the proper config variable, or use Flow's answer:

git -c http.sslVerify=false clone https://github.com/jasontaylordev/CleanArchitecture.git
To disable SSL verification for a specific repository
If the repository is completely under your control, you can try:

git config --global http.sslVerify false


git push -u origin master


git config --global user.name "${YOUR_NAME}"
git config --global user.email "${YOUR_EMAIL}


git remote get-url origin

//show tags
git tag

// push all tags
git push origin release --tags
git push origin --tags

// push single tag
git push origin [tag name]

// delete tag in repo
git push --delete origin tagname


// go to target branch use this commad
git merge sourceBranch/name --no-ff --commit -m "Merged PR 101: asdf - [x] prerelease"
git merge hotfix/test --no-ff --commit -m "Merged PR 101: asdf - [x] prerelease"


// force login again
git config --system --unset credential.helper


// undo staged changes... 'git reset HEAD' will unstage all changes and 'git checkout .' discards all the changes.
git reset HEAD
git checkout .



// emoty commit
git commit --allow-empty -m "Trigger Build"
git commit --allow-empty -m "update version to 1.."


git -c user.name="Codex" -c user.email="codex@openai.com" commit -m "add YTM synchronization job +semver: feature"

// remove remote tag
1. Delete the local tag
git tag -d <tag-name>

2. Delete the remote tag
git push origin --delete <tag-name>

Example
To delete a tag named v1.2.0:
git tag -d v1.2.0
git push origin --delete v1.2.0

3. Verify the deletion (optional)
Check local tags:
git tag -l

Check remote tags:
git ls-remote --tags origin

Note: Deleting the remote tag does not automatically remove it from other developers' local repositories. If they have fetched the tag, they can delete it locally using git tag -d v1.2.0.

If you want to clean up stale remote-tracking tags locally, run:
git fetch origin --prune --prune-tags --force