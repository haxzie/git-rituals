# git-rituals — branch shortcut functions for fish shell

set -g _GIT_RITUALS_DIR "$HOME/.git-rituals"
set -g _GIT_RITUALS_CONFIG "$_GIT_RITUALS_DIR/config"
set -g _GIT_RITUALS_VERSION "1.0.0"

# Load enabled rituals from config
set -g _git_rituals_enabled

if test -f "$_GIT_RITUALS_CONFIG"
    set -l config_line (grep '^RITUALS=' "$_GIT_RITUALS_CONFIG" | sed 's/^RITUALS=//')
    if test -n "$config_line"
        set _git_rituals_enabled (string split ',' -- $config_line)
    end
end

# Check if a ritual is enabled
function _git_ritual_is_enabled
    set -l name $argv[1]
    # If no config / empty list, all are enabled
    if test (count $_git_rituals_enabled) -eq 0
        return 0
    end
    contains -- $name $_git_rituals_enabled
end

# Slugify a string: lowercase, special chars to hyphens, collapse doubles, trim edges
function _git_ritual_slugify
    set -l input (string join ' ' -- $argv)
    set -l result (string lower -- $input)
    set result (string replace -ra '[^a-z0-9-]' '-' -- $result)
    set result (string replace -ra '-+' '-' -- $result)
    set result (string trim -c '-' -- $result)
    printf '%s' $result
end

# Core branch creation function
function _git_ritual
    set -l type $argv[1]
    set -l args $argv[2..-1]

    if test (count $args) -eq 0
        printf 'Usage: %s <branch-name>\n' $type >&2
        printf 'Example: %s my cool feature\n' $type >&2
        return 1
    end

    # Must be inside a git repo
    if not git rev-parse --is-inside-work-tree >/dev/null 2>&1
        printf 'fatal: not a git repository (or any of the parent directories)\n' >&2
        return 1
    end

    # Get git user name
    set -l username (git config user.name)
    if test -z "$username"
        printf 'error: git user.name is not set\n' >&2
        printf 'Fix it with: git config --global user.name "Your Name"\n' >&2
        return 1
    end

    set -l user_slug (_git_ritual_slugify $username)
    set -l name_slug (_git_ritual_slugify $args)

    if test -z "$name_slug"
        printf 'error: branch name resolves to empty after slugification\n' >&2
        return 1
    end

    set -l date_stamp (date +%d%m%Y)
    set -l branch "$type/$user_slug/$name_slug-$date_stamp"

    # If branch already exists, switch to it
    if git show-ref --verify --quiet "refs/heads/$branch"
        printf 'Branch already exists, switching to it\n'
        git checkout $branch
    else
        git checkout -b $branch
    end
end

# --- Ritual command definitions ---

function feat -d "Create a feat/* branch"
    if not _git_ritual_is_enabled feat
        printf 'error: feat ritual is disabled\n' >&2
        return 1
    end
    _git_ritual feat $argv
end

function fix -d "Create a fix/* branch"
    if not _git_ritual_is_enabled fix
        printf 'error: fix ritual is disabled\n' >&2
        return 1
    end
    _git_ritual fix $argv
end

function chore -d "Create a chore/* branch"
    if not _git_ritual_is_enabled chore
        printf 'error: chore ritual is disabled\n' >&2
        return 1
    end
    _git_ritual chore $argv
end

function refactor -d "Create a refactor/* branch"
    if not _git_ritual_is_enabled refactor
        printf 'error: refactor ritual is disabled\n' >&2
        return 1
    end
    _git_ritual refactor $argv
end

function docs -d "Create a docs/* branch"
    if not _git_ritual_is_enabled docs
        printf 'error: docs ritual is disabled\n' >&2
        return 1
    end
    _git_ritual docs $argv
end

function style -d "Create a style/* branch"
    if not _git_ritual_is_enabled style
        printf 'error: style ritual is disabled\n' >&2
        return 1
    end
    _git_ritual style $argv
end

function perf -d "Create a perf/* branch"
    if not _git_ritual_is_enabled perf
        printf 'error: perf ritual is disabled\n' >&2
        return 1
    end
    _git_ritual perf $argv
end

# Push current branch to remote
function push -d "Push current branch to remote"
    if not git rev-parse --is-inside-work-tree >/dev/null 2>&1
        printf 'fatal: not a git repository (or any of the parent directories)\n' >&2
        return 1
    end

    set -l branch (git rev-parse --abbrev-ref HEAD)

    if git config "branch.$branch.remote" >/dev/null 2>&1
        git push $argv
    else
        git push -u origin $branch $argv
    end
end

# Pull current branch from remote
function pull -d "Pull current branch from remote"
    if not git rev-parse --is-inside-work-tree >/dev/null 2>&1
        printf 'fatal: not a git repository (or any of the parent directories)\n' >&2
        return 1
    end

    git pull $argv
end

# Meta-command
function git-rituals -d "git-rituals meta command"
    switch "$argv[1]"
        case list
            printf 'git-rituals v%s\n\n' $_GIT_RITUALS_VERSION
            printf 'Available rituals:\n'
            for r in feat fix chore refactor docs style perf push pull
                if _git_ritual_is_enabled $r
                    printf '  %-12s [enabled]\n' $r
                else
                    printf '  %-12s [disabled]\n' $r
                end
            end
            printf '\nBranch rituals:\n'
            printf '  <ritual> <branch-name>    Create and switch to branch\n'
            printf '  Example: feat add login page\n'
            printf '    Creates: feat/<your-name>/add-login-page-07022026\n'
            printf '\nShortcuts:\n'
            printf '  push                      Push current branch to remote\n'
            printf '  pull                      Pull current branch from remote\n'
        case uninstall
            if test -f "$_GIT_RITUALS_DIR/uninstall.sh"
                bash "$_GIT_RITUALS_DIR/uninstall.sh"
            else
                printf 'error: uninstall script not found at %s/uninstall.sh\n' $_GIT_RITUALS_DIR >&2
                return 1
            end
        case version
            printf 'git-rituals v%s\n' $_GIT_RITUALS_VERSION
        case '*'
            printf 'git-rituals v%s\n\n' $_GIT_RITUALS_VERSION
            printf 'Commands:\n'
            printf '  git-rituals list        Show available rituals\n'
            printf '  git-rituals uninstall   Remove git-rituals\n'
            printf '  git-rituals version     Show version\n'
    end
end
