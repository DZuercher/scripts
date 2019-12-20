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
git_repos=('git@cosmo-gitlab.phys.ethz.ch:cosmo/ethz-des-mccl.git' 'git@cosmo-gitlab.phys.ethz.ch:rsgier/ECl.git' 'git@cosmo-gitlab.phys.ethz.ch:cosmo/ucat.git' 'git@cosmo-gitlab.phys.ethz.ch:cosmo/ufig.git' '-b 11-test-intrinsic-alignments git@cosmo-gitlab.phys.ethz.ch:cosmo/PyCosmo.git' 'git@cosmo-gitlab.phys.ethz.ch:cosmo/esub.git')

# modules to load (if on euler)
modules=('new' 'python/3.7.1' 'intel/2018.1' 'gcc/4.8.2' 'open_mpi/3.0.0')

# python binary
py_bin='python'
# pip binary
pip_bin='pip'

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

        # adding exception for PyCosmo which
        # needs build of C modules
        if [ "$repo" == "PyCosmo/" ];
        then
          printf "C library \n"
          ${pip_bin} install numpy
          ${pip_bin} install Cython
          ${py_bin} setup.py develop
        fi

        ${pip_bin} install -e .
        cd ..
    done
}

function load_modules {
    # loads the modules on euler
    for module in "${modules[@]}";
    do
         printf "Loading module ${module} \n"
         module load ${module}

         # append modules to environment
         if [ "$1" == "log" ];
         then
             printf $module >> environment
         fi
     done

     if [ "$1" == "log" ];
     then
         printf "\n \n" >> environment
     fi
}

function write_esub_source_file {
    # writes the esub source file automatically
    printf "Writing esub source file \n"
    if [ "$1" == "euler" ];
    then
      for module in "${modules[@]}";
      do
        printf "module load ${module} \n" >> source/source_esub.sh
      done
      printf "\n \n" >> source/source_esub.sh
    fi

    printf 'export ESUB_LOCAL_SCRATCH=$TMPDIR' >> source/source_esub.sh
    printf "\n" >> source/source_esub.sh
    printf 'export SUBMIT_DIR=`pwd`' >> source/source_esub.sh

}

# intialize workspace
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
    printf "Author: ${author} \n \n" >> pipe
    printf "######################## VARIABLES ################## \n" >> pipe
    printf '%s\n' '- parameters:' >> pipe
    printf '%s\n' '  - source_file: source/source_esub.sh' >> pipe

    touch environment

    # Load modules on demand
    if [ "$2" == "euler" ];
    then
        load_modules log
    fi

    # create virtual environment
    ${py_bin} -m venv env

    # activating the environment
    activate_env

    # create subdirectories
    printf "Creating subdirectories data, source and repos \n"
    mkdir data
    mkdir source
    mkdir repos

    # write esub source file
    write_esub_source_file $2

    cd repos
    init_repos
    cd ..

    printf $"pip freeze: \n" >> environment
    ${pip_bin} freeze >> environment

    # source esub file
    source source/source_esub.sh

# activate workspace
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

    # source esub file
    source source/source_esub.sh
fi

