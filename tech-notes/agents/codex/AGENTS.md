# AGENTS.md

Diego Pacheco Codex AGENTS global guidelines.

## General Guidelines

* Never use comments, never comment anything.
* Never use the words: "demo", "demonstration" or "example", never ever.
* Make sure the code is as simple as possible.
* Make sure the code is well written and make sense.
* Do not do things I did not ask for in explicit prompts.
* Use the least number of libraries as possible, if possible no libraries.

## Github Pull Request(PR) Guidelines

* Always explain the task
* Always put the whole prompt on the PR description
* Always run the tests and get the test output on the PR.

## When Writing BASH scripts

* Never use comments, never ever.
* Never do sleep bigger than 1
* When need to wait for a POD or a docker container in docker or k8s make sure you will use a loop and check the condition and do max sleep 1.
* Dont use icons and enomjis on bash script.

## Dockerfile/Containerfile

* Prefer name the file as Containerfile
* Never use Docker, always use podman and podman-compose
* Make sure you are using the latest versions
* Do not write comments, never comment.
* Make sure you dont do ENTER between commands make it compact

## podman-compose

* Never use docker-compose always use podman-compose
* This section only apply if you have podman-compose requirements otherwise ignore it.
* docker-compose it's alias to podman, keep that in mind.
* always have a start.sh where you start docker-compose.
* always have a stop.sh to stop docker-compose.
* always have a test.sh where you show the feature is working.
* "dont use timeouts more than 1min"
