#!/usr/bin/env bash

set -e

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

    # Ensure JupyterHub directory exists.
    setup_directory ${jupyterhub_root}

#    # Delete old files, if they are there.
#    rm -f "${jupyterhub_root}/jupyterhub.sqlite"
#    rm -f "${jupyterhub_root}/jupyterhub_cookie_secret"

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
    USER="${1}"
    HOME="/home/${USER}"

    local course="${2}"
    local runas="sudo -u ${USER}"
    local currdir="$(pwd)"

    cd "${HOME}"
    ${runas} nbgrader quickstart "${course}"

    cd "${course}"
    # ${runas} ${nbgrader} generate_assignment ps1 
    # ${runas} ${nbgrader} release_assignment ps1 

    cd "${currdir}"
} 

    

enable_create_assignment () {
    USER="${1}"
    HOME="/home/${USER}"
    local runas="sudo -u ${USER}"

    ${runas} jupyter nbextension enable --user create_assignment/main
}


enable_formgrader () { 
    USER="${1}"
    HOME="/home/${USER}"

    local runas="sudo -u ${USER}"
    ${runas} jupyter nbextension enable --user formgrader/main --section=tree
    ${runas} jupyter serverextension enable --user nbgrader.server_extensions.formgrader
} 



enable_assignment_list () { 
    USER="${1}"
    HOME="/home/${USER}"

    local runas="sudo -u ${USER}"
    ${runas} jupyter nbextension enable --user assignment_list/main --section=tree
    ${runas} jupyter serverextension enable --user nbgrader.server_extensions.assignment_list
} 



enable_course_list () { 
    USER="${1}"
    HOME="/home/${USER}"

    local runas="sudo -u ${USER}"

    ${runas} jupyter nbextension enable --user course_list/main --section=tree
    ${runas} jupyter serverextension enable --user nbgrader.server_extensions.course_list
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
