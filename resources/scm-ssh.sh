#!/bin/bash
export SSH_SCM_AUTH_SOCK="$HOME/.ssh/scm-agent.sock"
SCRIPT_VERSION=1

# Starts the custom SSH agent.
start_scm_ssh_agent() {
    # Check if the socket file exists
    if [ -S "$SSH_SCM_AUTH_SOCK" ]; then
        # If the socket exists, check if the SSH agent process is running
        AGENT_PID=$(ps aux | grep $SSH_SCM_AUTH_SOCK | grep -v grep | head -1 | awk '{print $2}')

        # If no associated process is found or the agent isn't running, start a new SSH agent
        if [ -z "$AGENT_PID" ]; then
            echo "Socket exists but no running agent, starting new SSH agent..."
            rm $SSH_SCM_AUTH_SOCK
            eval $(ssh-agent -a "$SSH_SCM_AUTH_SOCK")
        else
            # If the agent is already running, use the existing one
            echo "SSH agent already running with PID: $AGENT_PID, using existing agent."
        fi
    else
        # If the socket doesn't exist, start a new SSH agent
        echo "Socket doesn't exist, starting new SCM SSH agent..."
        ssh-agent -a "$SSH_SCM_AUTH_SOCK"
    fi
}

# Stops the custom SSH agent.
stop_scm_ssh_agent() {
    # Check if the socket file exists
    if [ -S "$SSH_SCM_AUTH_SOCK" ]; then
        # If the socket exists, check if the SSH agent process is running
        AGENT_PID=$(ps aux | grep $SSH_SCM_AUTH_SOCK | grep -v grep | head -1 | awk '{print $2}')

        # If no associated process is found or the agent isn't running, start a new SSH agent
        if [ -z "$AGENT_PID" ]; then
            echo "Socket exists but no running agent, removing the socket..."
            rm $SSH_SCM_AUTH_SOCK
        else
            # If the agent is already running, use the existing one
            echo "Killing SSH agent running with PID: $AGENT_PID ..."
            SSH_AGENT_PID=$AGENT_PID ssh-agent -k
        fi
    else
        # If the socket doesn't exist, start a new SSH agent
        echo "Socket doesn't exist, nothing to do to stop SSH agent."
    fi
}

ssh_add() {
    ssh_reset
}

ssh_reset() {
    echo "Clearing and reloading the card..."
    local providers=("/usr/local/lib/libykcs11.dylib" "/usr/lib64/opensc-pkcs11.so" "/usr/local/lib/opensc-pkcs11.so")
    
    if [[ -S "$SSH_SCM_AUTH_SOCK" ]]; then
        SSH_AUTH_SOCK="$SSH_SCM_AUTH_SOCK" ssh-add -D
        
        local provider_path="$1"
        if [[ -z "$provider_path" ]]; then
            for path in "${providers[@]}"; do
                if [[ -e "$path" ]]; then
                    echo "Using provider '${provider_path}'"
                    SSH_AUTH_SOCK="$SSH_SCM_AUTH_SOCK" ssh-add -e "$path"
                    SSH_AUTH_SOCK="$SSH_SCM_AUTH_SOCK" ssh-add -s "$path"
                    return
                fi
            done
        elif [[ -e "$provider_path" ]]; then
            SSH_AUTH_SOCK="$SSH_SCM_AUTH_SOCK" ssh-add -e "$provider_path"
            SSH_AUTH_SOCK="$SSH_SCM_AUTH_SOCK" ssh-add -s "$provider_path"
        else
            echo "Invalid provider path: $provider_path"
            return 1
        fi
    else
        read -p "SSH agent socket not found at $sock_path. Continue with default SSH Agent (without SSH_AUTH_SOCK) or you may run 'start_agent' command to setup one? (y/n): " confirm
        if [[ "$confirm" != "y" ]]; then
            echo "Aborted."
            return 1
        fi

        ssh-add -D

        local provider_path="$1"
        if [[ -z "$provider_path" ]]; then
            for path in "${providers[@]}"; do
                if [[ -e "$path" ]]; then
                    ssh-add -e "$path"
                    ssh-add -s "$path"
                    return
                fi
            done
        elif [[ -e "$provider_path" ]]; then
            ssh-add -e "$provider_path"
            ssh-add -s "$provider_path"
        else
            echo "Invalid provider path: $provider_path"
            return 1
        fi
    fi
}

install() {
    local script_path="$HOME/.ssh/scm-script.sh"
    mkdir -p "$HOME/.ssh"
    chmod 700 $HOME/.ssh
    cp "$0" "$script_path"
    chmod +x "$script_path"


    if [ "$(uname)" == "Darwin" ]; then
        install_yubico_piv_tool_mac     
    elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
        install_yubico_piv_tool_linux
    else
        echo "Unsupported OS"
        return 1
    fi


    local profile_file
    if [[ $SHELL == "/bin/bash" ]]; then
        profile_file="$HOME/.bashrc"
    else
        profile_file="$HOME/.zshrc"
    fi
    
    if ! grep -q "Include config-scm" "$HOME/.ssh/config"; then

cat <<< "Include config-scm
$(cat $HOME/.ssh/config)
" > $HOME/.ssh/config

cat > $HOME/.ssh/config-scm << EOF
Host oci*.private.devops.scmservice.*.oci.oracleiaas.com
   User $(whoami)@bmc_operator_access
   IdentityAgent $HOME/.ssh/scm-agent.sock
EOF
    fi

    if ! grep -q "alias scm-ssh='$script_path'" "$profile_file"; then
        echo "" >> "$profile_file"
        echo "" >> "$profile_file"
        echo "alias scm-ssh='$script_path'" >> "$profile_file"
        echo "scm-ssh start_agent" >> "$profile_file"
    fi

    
    echo "SCM script installed successfully. Please restart your terminal or run 'source $profile_file' to apply changes."
}

install_yubico_piv_tool_linux() {
    local providers=("/usr/local/lib/libykcs11.dylib" "/usr/lib64/opensc-pkcs11.so" "/usr/local/lib/opensc-pkcs11.so")

    for path in "${providers[@]}"; do
        if [[ -e "$path" ]]; then
            return
        fi
    done

    echo "Automatic install not supported. Please install OpenSC or Yubico PIV Tool manually."
}

install_yubico_piv_tool_mac() {
    local url="https://developers.yubico.com/yubico-piv-tool/Releases/yubico-piv-tool-latest-mac-universal.pkg"
    local pkg_file="/tmp/yubico-piv-tool-latest-mac-universal.pkg"
    local lib_path="/usr/local/lib/libykcs11.dylib"

    if [[ -f $lib_path ]]; then
        echo "Yubico PIV tool is already installed at $lib_path. Skipping..."
        return 0
    fi


    echo "Downloading Yubico PIV Tool..."
    curl -L "$url" -o "$pkg_file"

    if [[ ! -f "$pkg_file" ]]; then
        echo "Download failed!"
        return 1
    fi



    echo "Installing Yubico PIV Tool... (sudo password might be required)"

    if sudo installer -pkg "$pkg_file" -target /; then
        echo "Installation of Yubico PIV Tool complete"
    else
        echo "Install failed"
        return 1
    fi

    # Cleanup
    rm "$pkg_file"

    echo "Verifying installation..."

    if [[ -f "$lib_path" ]]; then
        echo "Library $lib_path is present!"
    else
        echo "Library $lib_path is missing! Installation might be incomplete."
        return 1
    fi
}

scm_script_help() {
    echo "Usage: $0 <command> [args...]"
    echo "---------------------------"
    echo "Commands:"
    echo "  start_agent                   - Starts the SCM ssh agent."
    echo "  stop_agent                    - Stops the SCM ssh agent."
    echo "  ssh_reset                     - Clears and reload the Yubikey to the agent."
    echo "  ssh_add                       - Alias to ssh_reset."
    echo "  install                       - Installs scm command by copying script to ~/.ssh/scm-script.sh and adding alias to the profile."
    echo "  install_yubico_piv_tool       - Download and install Yubikey PIV tool"
    echo "  help                          - Displays this help message."
    echo "---------------------------"
    echo "Completed execution of SCM Script v${SCRIPT_VERSION}."
}

# Prevent execution when sourced in both bash and zsh
if [[ -n "$ZSH_VERSION" ]]; then
    return  # For zsh
elif [[ -n "$BASH_VERSION" && "${BASH_SOURCE[0]}" != "$0" ]]; then
    return  # For bash
fi

# Check if at least one argument is provided
if [ "$#" -lt 1 ]; then
    scm_script_help
    exit 1
fi

# Extract the command
COMMAND="$1"
shift  # Remove the first argument

# Execute the corresponding function
case "$COMMAND" in
    start_agent)
        start_scm_ssh_agent "$@"
        ;;
    stop_agent)
        stop_scm_ssh_agent "$@"
        ;;
    ssh_reset)
        ssh_reset "$@"
        ;;
    ssh_add)
        ssh_add "$@"
        ;;
    install)
        install "$@"
        ;;
    install_yubico_piv_tool)
            install_yubico_piv_tool "$@"
            ;;
    *)
        echo "Invalid command. Use help."
        exit 1
        ;;
esac
echo "Completed execution of SCM Script v${SCRIPT_VERSION}."
