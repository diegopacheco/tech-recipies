# Git

#### 1 - How to Create a Branch in Git/GitHub and PUSH it REMOTE?

```bash
git checkout -b [name_of_your_new_branch]
git push origin [name_of_your_new_branch]
git branch
```

#### 2 - How to CLONE a remote branch in GitHub?

```bash
git clone -b [branch_name] [remote_repo_git]
```

#### 2.1 - How create remote branch upstream in GitHub?

```bash
git checkout -b [name_of_your_new_branch]
git push origin [name_of_your_new_branch]
git push upstream [name_of_your_new_branch]
```

#### 3 - How to DELETE a LOCAL BRANCH?

Delete LOCAL
```bash
git branch -d [NAME_OF_LOCAL_BRANCH]
# IF you want to FORCE to delete you can do
git branch -D [NAME_OF_LOCAL_BRANCH]
```
Delete REMOTE
```bash
git push origin --delete NAME_OF_REMOTE_BRNACH
```

#### 4 - How to Download a GitHub Pull Request?

```bash
git clone [GIT_URL_MASTER]
git fetch origin pull/[PULL_REQUEST_ID]/head:[GIT_BRANCHNAME]
git checkout [GIT_BRANCHNAME]
```

#### 5 - How to Sync a FORK with/from MASTER?

```bash
git remote -v 
git remote add upstream [HTTPS_URL_GIT_MASTER]
git remote -v 
git fetch upstream 
git checkout master 
git merge upstream/master 
```

#### 6 - GitHub How to Sync a Branch inside a FORK with the Original Master for PR?

```bash
git checkout [BRANCH_I_WANT_SYNC]
git remote -v 
git remote add upstream [HTTPS_URL_GIT_MASTER] 
git remote -v 
git fetch upstream 
git merge upstream/master 
# RESOLVE ALL CONFICTS - IF THERE ARE ANY
git commit -m "Merge Master" 
git push 
```

#### 7 - How to download a remote branch from github/git?
```bash
git fetch origin $remote-branch:$new-local-branch
```

#### 8 - How to create a Tag?
```bash
git tag
git tag -a v1.4 -m "my version 1.4"
git tag
git push origin v1.4
```

#### 9. How to undo git add?
```bash
git reset 
git status
```

#### 10. How to Delete a remote Branch in github?
```bash
git push origin --delete $remote-branch-name
```

#### 11. How to create an Empty branch in github? 
```bash
git checkout --orphan $NEWBRANCH-NAME
git rm -rf .
# Edit your files
git add .
git commit -m "my commit"
git push
```

#### 12. How to list all REMOTE branchs?
```bash
git branch -a
```

#### 13. How to clone a TAG ? 
```bash
git clone <repo_git>
git checkout tags/<tag_name> -b <branch_name>
```

#### 14. Git Sync / Merge (master) - Preference Upstream and remove deleted?
```bash
git fetch upstream
git merge upstream/master --strategy-option theirs
git status --porcelain | awk '{if ($1=="UD") print $2}' | xargs git rm
git commit -m "Merge Master"
git push 
```

#### 15. REVERT last 3 commits(will remove files from FS)
```bash
# Backup first :-)
git reset --hard HEAD~3
```

### 16. How to checkout remote branch?
```bash
git checkout -b master origin/master 
```

#### 17. how to see TOP Commiters?

```bash
git shortlog -s -n
```
