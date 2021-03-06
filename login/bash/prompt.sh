#!/usr/bin/env bash

# For git-managed directories, make a nice prompt.
git-prompt () {

	if ! has-command git; then
		return 0
	fi

	GIT_BRANCH="$(git branch 2> /dev/null | grep '^\*')"
	if test -z "${GIT_BRANCH}"; then
		return 0
	fi

	GIT_BRANCH="${GIT_BRANCH:2}"
	GIT_BRANCH="$(printf "%s" "${GIT_BRANCH}")"
	echo -e " ${Red}[${GIT_BRANCH}]${Color_Off}"
}

# When running within docker, make that obvious.
docker-prompt () {
	if [ -n "${DOCKER}" ]; then
		echo -e "${Purple}(docker)${Color_Off} "
	fi
}

# Override prompt_command to use the aforementioned git_prompt
prompt-command () {
	GIT_PROMPT="$(git-prompt)"
	DOCKER_PROMPT="$(docker-prompt)"
	export PS1="${DOCKER_PROMPT}${Cyan}\u${Color_Off}${White}@${Color_Off}${Red}\h${Color_Off}${White}:${Color_Off}${BYellow}\w${Color_Off}${GIT_PROMPT}\\n$ "
}

if [ -f /.dockerenv ]; then
	DOCKER=1
fi

PROMPT_COMMAND="prompt-command"
export PROMPT_COMMAND
