# Automatically Generate Release Notes for GitHub Release

```sh
$ git rev-list --tags --skip=1 --max-count=1
c07d4d896ea4b5c5db9bd91033f5e10dee71603a

$ git describe --abbrev=0 --tags c07d4d896ea4b5c5db9bd91033f5e10dee71603a
1.10.0

$ git log --pretty=format:"%h %s" 1.10.0 1.11.0
da787db Some commit C
c07d4d8 Some commit B
1830ecc Some commit A
```

```yml
before_deploy:
  - ps: $prev_commit=git rev-list --tags --skip=1 --max-count=1
  - ps: $prev_tag=git describe --abbrev=0 --tags $prev_commit
  - ps: $range=$prev_tag + ".." + $appveyor_repo_tag_name
  - ps: $release_notes=git log --pretty=format:"%h %s" $range
  - ps: Set-AppveyorBuildVariable -Name release_notes -Value $release_notes

deploy:
  - provider: GitHub
    description: '$(release_notes)'
    release: '$(appveyor_repo_tag_name)'
    artifact: /.*\.nupkg/
    auth_token:
      secure: [secure key]
    on:
      appveyor_repo_tag: true
```