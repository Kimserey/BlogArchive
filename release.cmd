echo off

REM Checkout release branch
git checkout release

REM Merge master to release
git merge master

REM Pushes on origin 
git push

REM Pushes on remote github, local/release to github/master 
git push github release:master

REM Checkout master branch
git checkout master

echo on