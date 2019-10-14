#! /usr/bin/bash

# creates a workspace when argument initialize is given
# eg ./setup_workspace.sh initialize [euler]

# if argument is activate, activates the environement
# eg .setup_workspace.sh activate [euler]

# if second argument is euler loads the modules specified in modules

#PARAMETERS
############################################################

#name of the workspace
name='/cluster/home/dominikz/20191014_DR1_MCCL_MAP_COMPARISON'

#author
author="Dominik Zuercher"

#git directories to clone
git_repos=('git@cosmo-gitlab.phys.ethz.ch:cosmo/esub.git' '-b modular git@cosmo-gitlab.phys.ethz.ch:DZuercher/UStats.git' 'git@cosmo-gitlab.phys.ethz.ch:rsgier/ECl.git')

#virtual python environement
venv='/cluster/home/dominikz/venv_3.6.1'

#modules to load (if on euler)
modules=('new' 'python/3.6.1' 'intel/2018.1' 'gcc/4.8.2' 'open_mpi/3.0.0')

############################################################3

function append_python_path {
    for i in $( ls -d repos/*/ );
    do
        printf "Adding repository $i to PYTHONPATH variable \n"
        export PYTHONPATH=$i:$PYTHONPATH
    done
}

function activate_env {
    #source virtual environement
    printf "Activating virtual python environement ${venv} \n"
    source ${venv}/bin/activate
}

function clone_repos {
    #clone repositories
    for repo in "${git_repos[@]}";
    do
        printf "Cloning ${repo} \n"
        git clone $repo
    done
}

function load_modules {
   for module in "${modules[@]}";
   do
        printf "Loading module ${module} \n"
        module load ${module}

        #append modules to environement
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

    #check if already exists
    if [ -d ${name} ];
    then
        printf "The workspace does already exist. Aborting \n"
        exit 0
    fi

    #create the top directory
    printf "Creating directory ${name} \n"
    mkdir ${name}
    cd ${name}

    #create doc files
    printf "Creating files README, pipe and environement \n"
    printf "Author: ${author}" >> README
    printf "Author: ${author}" >> pipe 

    touch environement

    #Load modules on demand
    if [ "$2" == "euler" ];
    then
        load_modules log 
    fi

    activate_env

    #create subdirectories
    printf "Creating subdirectories data, source and repos \n"
    mkdir data
    mkdir source
    mkdir repos

    cd repos
    clone_repos
    cd ..

    append_python_path

    printf $"pip freeze: \n" >> environement
    pip freeze >> environement

elif [ "$1" == "activate" ];
then

    printf "Activating workspace in ${name} \n"

    #Load modules on demand
    if [ "$2" == "euler" ];
    then
        load_modules
    fi

    activate_env

    cd ${name}

    append_python_path

fi

