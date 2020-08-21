#!/usr/bin/env bash
# Configuration variables.
root="/root"
srv_root="/srv/nbgrader"
nbgrader_root="/srv/nbgrader/nbgrader"
jupyterhub_root="/srv/nbgrader/jupyterhub"
exchange_root="/srv/nbgrader/exchange"

# List of possible users, used across all demos.
possible_users=(
    'instructor1'
#    'instructor2'
#    'grader-course101'
#    'grader-course123'
    'student1'
)


setup_directory () {
    local directory="${1}"
    local permissions="${2}"
    echo "Creating directory '${directory}' with permissions '${permissions}'"
    if [ ! -d "${directory}" ]; then
        mkdir -p "${directory}"
        if [[ ! -z "${permissions}" ]]; then
            chmod "${permissions}" "${directory}"
        fi
    fi
}


init_nbgrader () {
    local nbgrader_root="${1}"
    local exchange_root="${2}"

    echo "Installing nbgrader in '${nbgrader_root}'..."

    # Install global extensions, and disable them globally. We will re-enable
    # specific ones for different user accounts in each demo.
    jupyter nbextension install --symlink --sys-prefix --py nbgrader --overwrite
    jupyter nbextension disable --sys-prefix --py nbgrader
    jupyter serverextension disable --sys-prefix --py nbgrader

    # Everybody gets the validate extension, however.
    jupyter nbextension enable --sys-prefix validate_assignment/main --section=notebook
    jupyter serverextension enable --sys-prefix nbgrader.server_extensions.validate_assignment

    # Reset exchange.
    rm -rf "${exchange_root}"
    setup_directory "${exchange_root}" ugo+rwx

    # Remove global nbgrader configuration, if it exists.
    rm -f /etc/jupyter/nbgrader_config.py
}


setup_jupyterhub () {
    local jupyterhub_root="${1}"

    echo "Setting up JupyterHub to run in '${jupyterhub_root}'"

    # Ensure JupyterHub directory exists.
    setup_directory ${jupyterhub_root}

    # Delete old files, if they are there.
    rm -f "${jupyterhub_root}/jupyterhub.sqlite"
    rm -f "${jupyterhub_root}/jupyterhub_cookie_secret"

    # Copy config file.
    cp jupyterhub_config.py "${jupyterhub_root}/jupyterhub_config.py"
}


setup_nbgrader () {
    USER="${1}"
    HOME="/home/${USER}"

    local config="${2}"
    local runas="sudo -u ${USER}"

    echo "Setting up nbgrader for user '${USER}'"

    ${runas} mkdir -p "${HOME}/.jupyter"
    ${runas} cp "${config}" "${HOME}/.jupyter/nbgrader_config.py"
    ${runas} chown "${USER}:${USER}" "${HOME}/.jupyter/nbgrader_config.py"
}



create_course () { 
    # path to the location of system-wide nbgrader
    nbgrader=/opt/applications/python/3.6.3/gnu/bin/nbgrader

    USER="${1}"
    HOME="/home/${USER}"

    local course="${2}"
    local runas="sudo -u ${USER}"
    local currdir="$(pwd)"

    cd "${HOME}"
    ${runas} ${nbgrader} quickstart "${course}"

    cd "${course}"
    # ${runas} ${nbgrader} generate_assignment ps1 
    # ${runas} ${nbgrader} release_assignment ps1 

    cd "${currdir}"
} 

    

enable_create_assignment () {
    jupyter=/opt/applications/python/3.6.3/gnu/bin/jupyter

    USER="${1}"
    HOME="/home/${USER}"
    local runas="sudo -u ${USER}"

    ${runas} ${jupyter} nbextension enable --user create_assignment/main
}


enable_formgrader () { 
    # path to the location of system-wide jupyter
    jupyter=/opt/applications/python/3.6.3/gnu/bin/jupyter

    USER="${1}"
    HOME="/home/${USER}"

    local runas="sudo -u ${USER}"
    ${runas} ${jupyter} nbextension enable --user formgrader/main --section=tree 
    ${runas} ${jupyter} serverextension enable --user nbgrader.server_extensions.formgrader 
} 



enable_assignment_list () { 
    # path to the location of system-wide jupyter
    jupyter=/opt/applications/python/3.6.3/gnu/bin/jupyter

    USER="${1}"
    HOME="/home/${USER}"

    local runas="sudo -u ${USER}"
    ${runas} ${jupyter} nbextension enable --user assignment_list/main --section=tree 
    ${runas} ${jupyter} serverextension enable --user nbgrader.server_extensions.assignment_list 
} 



enable_course_list () { 
    # path to the location of system-wide jupyter
    jupyter=/opt/applications/python/3.6.3/gnu/bin/jupyter

    USER="${1}"
    HOME="/home/${USER}"

    local runas="sudo -u ${USER}"

    ${runas} ${jupyter} nbextension enable --user course_list/main --section=tree 
    ${runas} ${jupyter} serverextension enable --user nbgrader.server_extensions.course_list 
}

make_user () {
    local user="${1}"
    echo "Creating user '${user}'"
    useradd "${user}"
    yes "${user}" | passwd "${user}"
    mkdir "/home/${user}"
    chown "${user}:${user}" "/home/${user}"
}


remove_user () {
    local user="${1}"
    echo "Removing user '${user}'"
    userdel "${user}" || true
    rm -rf "/home/${user}"
}

students=(student1 student2 student3)

remove_user instructor1
for student in ${students[@]}; do
    remove_user "${student}"
done

#mkdir /home

##########################################################

#demo=demo_one_class_multiple_graders
demo=demo_one_class_one_grader

cd /root/${demo}

setup_directory "${srv_root}" ugo+r
init_nbgrader "${nbgrader_root}" "${exchange_root}"

# Setup the specific demo.
echo "Setting up demo '${demo}'..."

setup_jupyterhub "${jupyterhub_root}"

##########################################################

# We don't need to create users for existed instructors
make_user instructor1
for student in ${students[@]}; do
    make_user "${student}"
done

setup_nbgrader instructor1 instructor_nbgrader_config.py

create_course instructor1 course101

##########################################################

# Enable extensions for instructor.
enable_create_assignment instructor1
enable_formgrader instructor1
enable_assignment_list instructor1

# Enable extensions for student.
for student in ${students[@]}; do
    enable_assignment_list "${student}"
done
