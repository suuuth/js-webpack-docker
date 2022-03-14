#!/usr/bin/env bash
#Change this line for project name!
PROJECTNAME="css"
function die()
{
    local _ret="${2:-1}"
    test "${_PRINT_HELP:-no}" = yes && print_help >&2
    echo "$1" >&2
    exit "${_ret}"
}

function begins_with_short_option()
{
    local first_option all_short_options='eoh'
    first_option="${1:0:1}"
    test "$all_short_options" = "${all_short_options/$first_option/}" && return 1 || return 0
}

# THE DEFAULTS INITIALIZATION - OPTIONALS
_arg_environment=
_arg_operation=


function print_help()
{
    printf '%s\n' "This script generates a docker-compose and the corresponding yml files. Optionally additional arguments can be supplied for environment and operation"
    printf 'Usage: %s [-e|--environment <arg>] [-o|--operation <arg>] [-h|--help]\n' "$0"
    printf '\t%s\n' "-e, --environment: override branch default and specify development, staging, production to generate the environment setup (default based on current git branch)"
    printf '\t%s\n' "-o, --operation: specify generate, build, build-push (default build-push)"
    printf '\t%s\n' "-h, --help: Prints help"
}


function parse_commandline()
{
    while test $# -gt 0
    do
        _key="$1"
        case "$_key" in
            -e|--environment)
                test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
                _arg_environment="$2"
                shift
                ;;
            --environment=*)
                _arg_environment="${_key##--environment=}"
                ;;
            -e*)
                _arg_environment="${_key##-e}"
                ;;
            -o|--operation)
                test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
                _arg_operation="$2"
                shift
                ;;
            --operation=*)
                _arg_operation="${_key##--operation=}"
                ;;
            -o*)
                _arg_operation="${_key##-o}"
                ;;
            -h|--help)
                print_help
                exit 0
                ;;
            -h*)
                print_help
                exit 0
                ;;
            *)
                _PRINT_HELP=yes die "FATAL ERROR: Got an unexpected argument '$1'" 1
                ;;
        esac
        shift
    done
}
parse_commandline "$@"

BASEDIR=${PWD/#$HOME/''}'/docker/yml'
BRANCH="$(git symbolic-ref HEAD | sed -e 's,.*/\(.*\),\1,')"
function clean_compose_paths() {
    #Replace file directory paths docker config generates for some reason
    sed -i "s~$BASEDIR~./~g" $OUTPUT.yml
    sed -i "s~.//~./~g" $OUTPUT.yml
    sed -i "s~https./~https://~g" $OUTPUT.yml
    sed -i "s~https?./~https?://~g" $OUTPUT.yml
    if [ $BRANCH == "production" ]
    then
      # Remove traefik auth
      sed -i "s~traefik.frontend.auth.basic.users: '\"\"'~~g" $OUTPUT.yml
    fi

}

OUTPUT=docker-compose

if [ -z "$_arg_environment" ]
	then
	    echo "\$var is empty"
	else
	    BRANCH=$_arg_environment
fi

if [ -z "$_arg_operation" ]
	then
	    OPERATION="build-push"
	else
	    OPERATION=$_arg_operation
fi



case $BRANCH in
    development )
        echo "Performing operations on development"
        OUTPUT=docker-compose
        echo "Building docker-compose.yml"
        docker-compose -f docker/yml/base.yml -f docker/yml/development.yml config > docker-compose.yml
        clean_compose_paths
        if [ "$OPERATION" = "build" ] || [ "$OPERATION" = "build-push" ]
        then
            echo "Building..."
            docker-compose build
        fi
        ;;
    ap-* )
        echo "Performing operations on development"
        OUTPUT=docker-compose
        echo "Building docker-compose.yml"
        docker-compose -f docker/yml/base.yml -f docker/yml/development.yml config > docker-compose.yml
        clean_compose_paths
        if [ "$OPERATION" = "build" ] || [ "$OPERATION" = "build-push" ]
        then
            echo "Building..."
            docker-compose build
        fi
        ;;
    staging )
        echo "Performing operations on staging"
        echo "Building docker-compose.yml"
        docker-compose -f docker/yml/base.yml  -f docker/yml/staging.yml  config > docker-compose.yml
        OUTPUT=docker-compose
        clean_compose_paths

        if [ "$OPERATION" = "build" ]
        then
            echo "Building.."
            docker-compose build
        fi

        if [ "$OPERATION" = "build-push" ]
        then
            echo "Building.."
            docker-compose build
            echo "Pushing.."
            docker-compose push
        fi
        echo "Building $PROJECTNAME-staging.yml"
        docker-compose -f docker/yml/base.yml  -f docker/yml/staging.yml  config > "$PROJECTNAME-staging.yml"
        OUTPUT="$PROJECTNAME-staging"
        clean_compose_paths
        ;;
    production )
        echo "Performing operations on production"
        echo "Building docker-compose.yml"
        docker-compose -f docker/yml/base.yml -f docker/yml/staging.yml -f docker/yml/production.yml  config > docker-compose.yml
        OUTPUT=docker-compose
        clean_compose_paths

        if [ "$OPERATION" = "build" ]
        then
            echo "Building..."
            docker-compose build
        fi

        if [ "$OPERATION" = "build-push" ]
        then
            echo "Building..."

            docker-compose build
            echo "Pushing..."
            docker-compose push
        fi
        echo "Building $PROJECTNAME-production.yml"
        docker-compose -f docker/yml/base.yml -f docker/yml/staging.yml -f docker/yml/production.yml config > "$PROJECTNAME-production.yml"
        OUTPUT="$PROJECTNAME-production"
        clean_compose_paths
        ;;
    * )
        echo "Branch not matched script exiting"
        ;;
esac
