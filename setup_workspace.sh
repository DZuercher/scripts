#! /usr/bin/bash

# Author: Dominik Zuercher 2019

# creates a workspace when argument initialize is given
# eg ./setup_workspace.sh initialize [euler]

# if argument is activate, activates the environment
# eg .setup_workspace.sh activate [euler]

# if second argument is euler loads the modules specified in modules

# PARAMETERS
############################################################

# name of the workspace
name='workspace_dir'

# author
author="Dominik Zuercher"

# git directories to clone
git_repos=('git@cosmo-gitlab.phys.ethz.ch:DZuercher/des_non_gaussian.git' '-b 11-test-intrinsic-alignments git@cosmo-gitlab.phys.ethz.ch:cosmo/PyCosmo.git')

# modules to load (if on euler)
modules=('new' 'python/3.6.1' 'intel/2018.1' 'gcc/4.8.2' 'open_mpi/3.0.0')

############################################################3

function activate_env {
    # source virtual environment
    printf "Activating virtual python environment env \n"
    source env/bin/activate
}

function init_repos {
    # clone repositories
    for repo in "${git_repos[@]}";
    do
        printf "Cloning ${repo} \n"
        git clone $repo
    done

    # install
    for repo in $( ls -d */ );
    do
        printf "Building ${repo} \n"
        cd $repo
        pip install -e .
        cd ..
    done
}

function load_modules {
   for module in "${modules[@]}";
   do
        printf "Loading module ${module} \n"
        module load ${module}

        # append modules to environement
        if [ "$1" == "log" ];
        then
            printf $module >> environement
        fi
    done

    if [ "$1" == "log" ];
    then
        printf "\n \n" >> environement
    fi
}

if [ "$1" == "initialize" ];
then

    printf "Initializing workspace in ${name} \n"

    # check if already exists
    if [ -d ${name} ];
    then
        printf "The workspace does already exist. Aborting \n"
        exit 0
    fi

    # create the top directory
    printf "Creating directory ${name} \n"
    mkdir ${name}
    cd ${name}

    # create doc files
    printf "Creating files README, pipe and environment \n"
    printf "Author: ${author}" >> README
    printf "Author: ${author}" >> pipe 

    touch environment

    # Load modules on demand
    if [ "$2" == "euler" ];
    then
        load_modules log 
    fi

    # create virtual environment
    python -m venv env

    # activating the environment
    activate_env

    # create subdirectories
    printf "Creating subdirectories data, source and repos \n"
    mkdir data
    mkdir source
    mkdir repos

    cd repos
    init_repos
    cd ..

    printf $"pip freeze: \n" >> environment
    pip freeze >> environment

elif [ "$1" == "activate" ];
then

    printf "Activating workspace in ${name} \n"

    # Load modules on demand
    if [ "$2" == "euler" ];
    then
        load_modules
    fi

    cd ${name}

    activate_env

fi

