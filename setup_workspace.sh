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
name='<path to your workspace directory>'

# author
author="Dominik Zuercher"

# git directories to clone
git_repos=('-b wavelets git@cosmo-gitlab.phys.ethz.ch:cosmo_public/NGSF.git')

# modules to load (if on euler)
modules=('new' 'python/3.6.1' 'intel/2018.1' 'gcc/4.8.4' 'open_mpi/3.0.0')

# python binary
py_bin='python'
# pip binary
pip_bin='pip'

############################################################3
function gen_source_file {
    printf "Writing esub source file \n"

    # modules
    for module in "${modules[@]}";
    do
        printf "module load ${module} \n" >> source/source_esub.sh
    done

    # activate environment
    printf "source ${name}/env/bin/activate \n" >> source/source_esub.sh
    printf 'export ESUB_LOCAL_SCRATCH=$TMPDIR \n' >> source/source_esub.sh
    printf 'export SUBMIT_DIR=`pwd` \n' >> source/source_esub.sh

    if [ "$1" == "euler" ];
    then
        # Allow parallelisation on euler
        printf 'if [[ -z "${LSB_MAX_NUM_PROCESSORS}" ]]; \n' >> source/source_esub.sh
        printf 'then \n' >> source/source_esub.sh
        printf '    export OMP_NUM_THREADS=1 \n' >> source/source_esub.sh
        printf '    export OPENBLAS_NUM_THREADS=1 \n' >> source/source_esub.sh
        printf '    export MKL_NUM_THREADS=1 \n' >> source/source_esub.sh
        printf '    export VECLIB_MAXIMUM_THREADS=1 \n' >> source/source_esub.sh
        printf '    export NUMEXPR_NUM_THREADS=1 \n' >> source/source_esub.sh
        printf 'else \n' >> source/source_esub.sh
        printf '    export OMP_NUM_THREADS=${LSB_MAX_NUM_PROCESSORS} \n' >> source/source_esub.sh
        printf '    export OPENBLAS_NUM_THREADS=${LSB_MAX_NUM_PROCESSORS} \n' >> source/source_esub.sh
        printf '    export MKL_NUM_THREADS=${LSB_MAX_NUM_PROCESSORS} \n' >> source/source_esub.sh
        printf '    export VECLIB_MAXIMUM_THREADS=${LSB_MAX_NUM_PROCESSORS} \n' >> source/source_esub.sh
        printf '    export NUMEXPR_NUM_THREADS=${LSB_MAX_NUM_PROCESSORS} \n' >> source/source_esub.sh
        printf 'fi' >> source/source_esub.sh
    fi
}

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
          ${py_bin} setup.py install
          export PYTHONPATH=${PYTHONPATH}:${name}/repos/PyCosmo
        else
            ${pip_bin} install -e .
        fi

        cd ..
    done
}

function load_modules {
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
    gen_source_file $2

    cd repos
    init_repos
    cd ..

    printf $"pip freeze: \n" >> environment
    ${pip_bin} freeze >> environment

    # source esub file
    source source/source_esub.sh

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

    export PYTHONPATH=${PYTHONPATH}:${name}/repos/PyCosmo

    # source esub file
    source source/source_esub.sh
fi

