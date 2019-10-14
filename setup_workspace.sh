#! /usr/bin/bash

# creates a workspace when argument initialize is given
# eg ./setup_workspace.sh initialize [euler]

# if argument is activate, activates the environement
# eg .setup_workspace.sh activate [euler]

# if second argument is euler loads the modules specified in modules

#PARAMETERS
############################################################

#name of the workspace
name='20191014_test'

#git directories to clone
git_repos=('git@cosmo-gitlab.phys.ethz.ch:cosmo/esub.git' '-b modular git@cosmo-gitlab.phys.ethz.ch:DZuercher/UStats.git' 'git@cosmo-gitlab.phys.ethz.ch:rsgier/ECl.git')

#virtual python environement
venv='/cluster/home/dominikz/venv_3.6.1'

#modules to load (if on euler)
modules=('new' 'python/3.6.1' 'intel/2018.1' 'gcc/4.8.2' 'open_mpi/3.0.0')

############################################################3

if [ "$1" == "initialize" ]
then

    printf "Initializing workspace in ${name}"

    #check if already exists
    if [ -d ${name} ];
    then
        printf "The workspace does already exist. Aborting \n"
        exit 0
    fi

    #create the top directory
    mkdir ${name}
    cd ${name}

    #create doc files
    printf "Author: Dominik Zuercher" >> README
    printf "Author: Dominik Zuercher" >> pipe 

    touch environement

    #Load modules on demand
    if [ "$2" == "euler" ]
    then
        printf $"Modules: \n" >> environement
        for module in "${modules[@]}";
        do
            module load $module

            #append modules to environement
            printf $module >> environement
        done
        printf "\n \n" >> environement
    fi

    #source virtual environement
    source ${venv}/bin/activate

    #create subdirectories
    mkdir data
    mkdir source
    mkdir repos

    #clone repositories
    cd repos
    for repo in "${git_repos[@]}";
    do
        git clone $repo
    done
    cd ..

    #append git repositories to pythonpath
    for i in $( ls -d repos/*/ );
    do
        export PYTHONPATH=$i:$PYTHONPATH
    done

    printf $"pip freeze: \n" >> environement
    pip freeze >> environement

elif [ "$1" == "activate" ]
then

    printf "Activating workspace in ${name}"

    #Load modules on demand
    if [ "$2" == "euler" ]
    then
        for module in modules;
        do
            module load $module
        done 
    fi

    #source virtual environement
    source ${venv}/bin/activate

    cd ${name}

    #append git repositories to pythonpath
    for i in $( ls -d repos/*/ );
    do
        export PYTHONPATH=$i:$PYTHONPATH
    done

fi

