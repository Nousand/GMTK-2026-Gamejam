# GMTK-2026-Gamejam
Repository for our submission to the GMTK gamejam 2026

## Git guide
- use `git add .` to track changed files
	- untracked files wont be saved when using `git commit`
- use `git rm ` to remove a file 
- use `git commit -m ""` to save all changes with a message
- use `git push` to upload these changes to the github repository
- use `git pull origin main` to download changes from the main branch
	- `main` can be replaced with another branch name
- use `git checkout -b ` or `git switch ` to switch branches

### Procedure to merge to main
1. Ensure you are in your own branch while developing
2. while in your own branch run `git pull origin main` to sync your branch with main
	- Ensure all merge conflicts are solved at this point
3. `git add .` to track all changes
4. ensure you run `git commit -m ""` after the pull to save changes
5. run `git push` to upload changes to your branch on github
6. *now on github*, open the `Pull requests` tab
7. press `New Pull Requests`
8. select your branch in `compare:`, then `create pull request`
9. Add a comment describing your changes, submit it
10. Wait for atleast one other person to approve the PR before merging it

[Worth looking at](https://dev.to/colocodes/learn-how-to-use-git-and-github-in-a-team-like-a-pro-2dk7)

[For a more friendly interface use Lazygit](https://github.com/jesseduffield/lazygit)
