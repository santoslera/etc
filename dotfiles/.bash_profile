# -*- tab-width: 4, indent-tabs-mode: t -*-

if [ -f ~/.bash_platform ]; then
	. ~/.bash_platform
fi

if [ -f ~/.bash_colors ]; then
	. ~/.bash_colors
fi

if [ -f ~/.bash_aliases ]; then
	. ~/.bash_aliases
fi

if [ -f ~/.bash_functions ]; then
	. ~/.bash_functions
fi

# Forcibly declare the terminal as 256 color
defvar TERM "xterm-256color"

# Figure out if we're running on a high DPI display. Primarily done
# to work around bugs in Qt Creator on Linux
if [ -n "${IS_LINUX}" ]; then
	RESOLUTION=`xrandr -q 2> /dev/null | grep '*' | head -n 1 | awk '{print($1)}'`
	RESOLUTION_X=`echo "${RESOLUTION}" | cut -d"x" -f1`
	RESOLUTION_Y=`echo "${RESOLUTION}" | cut -d"x" -f2`
	if test "${RESOLUTION_X}" -ge 3840 -a "${RESOLUTION_Y}" -ge 2160; then
		defvar QT_DEVICE_PIXEL_RATIO 2
	fi
fi

# Manually set up the PATH, just to ensure that all utilities we might want are
# available (in the right order).
defjoined PATH ":"                  \
			  "/usr/local/bin"      \
			  "/usr/local/sbin"     \
			  "/usr/bin"            \
			  "/usr/sbin"           \
			  "/bin"                \
			  "/sbin"               \
			  "/sbin/opt/X11/bin"   \
			  "/Library/TeX/texbin" \
			  "/usr/texbin"

# Exports variables
defvar                                                  \
    NAME               "`rot13 'Xriva Hfurl'`"          \
    EMAIL              "`rot13 'xrivahfurl@tznvy.pbz'`" \
    EDITOR             "vim"                            \
    GNUTERM            "x11"                            \
                                                        \
    color_prompt       "yes"                            \
    force_color_prompt "yes"                            \
    CLICOLORS          "1"                              \
    LSCOLORS           "ExFxBxDxCxegedabagacad"         \
                                                        \
    PYTHONSTARTUP      ".pythonstartup.py"              \
    NODE_PATH          "/usr/local/lib/node"

# Go
export GOPATH=~/goprojects
if [ -n "${IS_DARWIN}" ]; then
	defvar GOROOT "/usr/local/opt/go/libxec"
fi

if [ -n "${GOROOT}" ]; then
	defvar PATH "$PATH:$GOPATH/bin:$GOROOT/bin"
fi

# Enable Bash-specific features
if test -n "$BASH"; then

	# Homebrew-related completion for bash on OS X
	if test -n "${IS_DARWIN}"; then

		if [ -f $(brew --prefix)/etc/bash_completion ]; then
			. $(brew --prefix)/etc/bash_completion
		fi

		if [ -f $(brew --prefix)/etc/bash_completion.d ]; then
			. $(brew --prefix)/etc/bash_completion.d
		fi

		if [ -f ~/git-completion.bash ]; then
			. ~/git-completion.bash
		fi

	fi

	# Enable git completion on Linux
	if [ -n "${IS_LINUX}" ]; then

		if [ ! -f ~/.git-completion.bash ]; then
			curl https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash -o ~/.git-completion.bash
		fi
		. ~/.git-completion.bash
	fi

	# For git-managed directories, make a nice prompt.
	git_prompt () {

		GIT_STATUS=$(git status -sb --porcelain 2> /dev/null | head -n 1)

		if test -n "${GIT_STATUS}"
		then
			GIT_STATUS=$(echo "${GIT_STATUS}" | sed 's|## *||')
			GIT_START=$(echo "${GIT_STATUS}" | sed 's|\.\.\..*||g')
			if [[ "${GIT_START}" =~ "no branch" ]]; then
				GIT_START=$(git -c color.status=false status | head -n 1)
			fi
			echo -e " ${Red}[${GIT_START}]${Color_Off}"
		else
			echo ""
		fi
	}

	# Override prompt_command to use the aforementioned git_prompt
	prompt_command () {
		GIT_PROMPT=$(git_prompt)
		# export PS1="\[\033[36m\]\u\[\033[m\]@\[\033[32m\]\h:\[\033[33;1m\]\w\[\033[m\]${GIT_PROMPT}\$ "
		export PS1="${Cyan}\u${Color_Off}${White}@${Color_Off}${Red}\h${Color_Off}${White}:${Color_Off}${BYellow}\w${Color_Off}${GIT_PROMPT}\\n$ "
	}

	export PROMPT_COMMAND=prompt_command


fi

