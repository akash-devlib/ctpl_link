#!/bin/bash
set -x

SSH_OPTIONS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
test_tools_bin_dir=$(python -c "import os; print (os.path.dirname(os.path.abspath(\"$0\")))")



_Usage(){
    echo "This script is to setup password-less ssh login from current host to a given remote host."
    echo "$(basename $0) -host <Remote Hostname> -user <username to login> -pass <password to login> [-port <port no> -home <home path> -nokeygen] "
    echo "$(basename $0) -help"
}

_keygen(){
    cmd="$(which ssh-keygen) -t rsa -f ${ID_RSA_PRIV}"
expect <<- DONE
spawn ${cmd}
expect {
"Enter file in which to save the key*"    { send "\r"; exp_continue }
"Enter passphrase (empty for no passphrase):*"  { send "\r" ; exp_continue}
"Enter same passphrase again:*"   { send "\r" ; exp_continue }
"*Enter passphrase for key*"   { send "\r" ; exp_continue }
"*Overwrite (y/n)*"   { send "y\r" ; exp_continue }
"*Overwrite (yes/no)*"   { send "yes\r" ; exp_continue }
}

DONE
if [[ ! -f "${ID_RSA}" ]] ; then
    echo "[ERROR] ${ID_RSA} not found"
    exit 1
else
    return 0
fi
} # _keygen END

_copyid_1(){
### trying to copy file using ssh-copy-id
cmd="${test_tools_bin_dir}/ssh-copy-id.1 ${SSH_OPTIONS} -i ${ID_RSA_PRIV} -p ${PORT} ${_USERNAME}@${REMOTE_HOST}"
expect <<-DONE
spawn ${cmd}
expect {
"*passphrase*id_rsa_vlink*"  { send "\r"; exp_continue }
"*yes/no*"                  { send "yes\r"; exp_continue }
"*assword*"                 { send "${PASSWORD}\r" ; exp_continue}
}
         
DONE

return $?

}

_copyid_2(){
### trying to copy file using ssh-copy-id
cmd="${test_tools_bin_dir}/ssh-copy-id.2 -i ${ID_RSA_PRIV} ${_USERNAME}@${REMOTE_HOST} -p ${PORT}"
expect <<-DONE
spawn ${cmd}
expect {
"*yes/no*"    { send "yes\r"; exp_continue }
"*assword*"  { send "${PASSWORD}\r" ; exp_continue}
}
         
DONE

return $?

}

_copyid_scp(){

### create remote host ~/.ssh dir
cmd="${SSH} -p ${PORT} ${_USERNAME}@${REMOTE_HOST} \"exec sh -c 'cd ; umask 077 ; mkdir -p .ssh ; touch .ssh/authorized_keys ;'\" "
expect <<- DONE
spawn ${cmd}
expect {
"*yes/no*"    { send "yes\r"; exp_continue }
"*assword*"  { send "${PASSWORD}\r" ; exp_continue}
}

DONE
 
### remove possible already exist entry in ~/.ssh/authorized_keys
case ${_platform} in
    CYGWIN)
        _HOSTNAME=$(ipconfig /all | grep -i 'host name' | awk '{print $NF}')
        _HOSTNAME=${_HOSTNAME%$'\r'}
        ;;
    *)
        _HOSTNAME=$(printf "%s" $(hostname))
        ;;
esac

WHOAMI="${_CUR_USER}@${_HOSTNAME}"
cmd="${SSH} -p ${PORT} ${_USERNAME}@${REMOTE_HOST} \"sed '/$WHOAMI/d' .ssh/authorized_keys > .ssh/authorized_keys.1; mv .ssh/authorized_keys.1 .ssh/authorized_keys\""
expect <<- DONE
spawn ${cmd}
expect {
"*yes/no*"    { send "yes\r"; exp_continue }
"*assword*"  { send "${PASSWORD}\r" ; exp_continue}
}

DONE

### scp id_rsa.pub over to remote host
cmd="scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -P ${PORT} ${ID_RSA} ${_USERNAME}@${REMOTE_HOST}:.ssh/id_rsa-${_HOSTNAME}.pub"
expect <<- DONE
spawn ${cmd}
expect {
"*yes/no*"    { send "yes\r"; exp_continue }
"*assword*"  { send "${PASSWORD}\r" ; exp_continue}
}

DONE

[[ "$?" != "0" ]] && echo "[ERROR] Failed to scp ${ID_RSA} to remote host." && return 1

cmd="${SSH} -p ${PORT} ${_USERNAME}@${REMOTE_HOST} cat .ssh/id_rsa-${_HOSTNAME}.pub >> .ssh/authorized_keys"
expect <<- DONE
spawn ${cmd}
expect {
"*yes/no*"    { send "yes\r"; exp_continue }
"*assword*"  { send "${PASSWORD}\r" ; exp_continue}
}

DONE

[[ "$?" != "0" ]] && echo "[ERROR] Failed to append id_rsa to remote host." && return 1

cmd="${SSH} -p ${PORT} ${_USERNAME}@${REMOTE_HOST} chmod 644 .ssh/authorized_keys"
expect <<- DONE
spawn ${cmd}
expect {
"*yes/no*"    { send "yes\r"; exp_continue }
"*assword*"  { send "${PASSWORD}\r" ; exp_continue}
}

DONE


cmd="${SSH} -p ${PORT} ${_USERNAME}@${REMOTE_HOST} \"exec sh -c 'if type restorecon >/dev/null 2>&1 ; then restorecon -F .ssh .ssh/authorized_keys ; fi' \" "
expect <<- DONE
spawn ${cmd}
expect {
"*yes/no*"    { send "yes\r"; exp_continue }
"*assword*"  { send "${PASSWORD}\r" ; exp_continue}
}

DONE


} # _copyid END

_verify(){
    ### Verify PASSWORD setup
    ${SSH} -i ${ID_RSA_PRIV} -o PreferredAuthentications=publickey -o BatchMode=yes -p ${PORT} ${_USERNAME}@${REMOTE_HOST} ls > /dev/null 2>&1
    [[ "$?" != "0" ]] \
        && { echo "[ERROR] passwordless login setup failed."; return 1; }
    echo "[COMPLETE] passwordless ssh from ${_HOSTNAME} to ${REMOTE_HOST} has been established."
    return 0
} # _verify END

_copy_and_verify(){
    case ${_platform} in
        SunOS)
            _copyid_2 && _verify && return 0
            echo "Copy ID 2: FAIL"
            _copyid_scp && _verify && return 0
            echo "Copy ID scp: FAIL"
            return 1;;
        *)
            _copyid_1 && _verify && return 0
            echo "Copy ID 1: FAIL"
            _copyid_2 && _verify && return 0
            echo "Copy ID 2: FAIL"
            _copyid_scp && _verify && return 0 
            echo "Copy ID scp: FAIL"
            return 1;;
    esac
}


################################################################################
# MAIN
################################################################################

if [ "$1" == "" ]; then
    _Usage
    exit 1
fi

# Defaults
NOKEYGEN=0

while [ "$1" != "" ]; do
    case $1 in
    -host )     shift
                REMOTE_HOST=$1
                ;;
    -user )     shift
                _USERNAME=$1
                ;;
    -pass )     shift
                PASSWORD=$1
                ;;
    -port )     shift
                PORT=$1
                ;;
    -home )     shift
                _HOME_DIR=$1
                ;;
    -nokeygen ) NOKEYGEN=1
                shift
                ;;
    -help|* )   _Usage
                exit 1
    esac
    shift
done
 

 
### Check variables
[[ "${REMOTE_HOST}" == "" ]] && echo "[ERROR] -host option is required." && exit 1
[[ "${_USERNAME}" == "" ]] && echo "[ERROR] -user option is required. " && exit 1
[[ "${PASSWORD}" == "" ]] && echo "[ERROR] -pass option is required. " && exit 1
[[ "${PORT}" == "" ]] && PORT=22 

### Getting platform
_platform=
if [ "$(uname -s | awk -F_ '{print $1}')" == "CYGWIN" ]; then
    _platform="CYGWIN"
else
    _platform=$(uname -s)
fi

### Check if id_rsa.pub is already there in ~/.ssh
case ${_platform} in
    CYGWIN)
        _CUR_USER=$(net config workstation | grep 'User name' | awk '{print $NF}')
        if [ "x$_CUR_USER" = "x" ] ; then
            _CUR_USER=$(id -un)
        fi
        _CUR_USER=${_CUR_USER%$'\r'}
        ;;
    *)
        _CUR_USER=$(printf "%s" $(whoami))
        ;;
esac

test -z ${_HOME_DIR} && _HOME_DIR=$(python3 -c "import os; print (os.path.expanduser('~'))")

test "${_platform}" == "CYGWIN" && _HOME_DIR=$(cygpath -u ${_HOME_DIR})

ID_RSA_PRIV="${_HOME_DIR}/.ssh/id_rsa_vlink"
ID_RSA="${_HOME_DIR}/.ssh/id_rsa_vlink.pub"

SSH="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "

### Check if passwordless is already set
${SSH} -i ${ID_RSA_PRIV} -o PreferredAuthentications=publickey -o BatchMode=yes -o ConnectTimeout=10 -p ${PORT} ${_USERNAME}@${REMOTE_HOST} ls > /dev/null 2>&1
[[ $? -eq 0 ]] && exit 0

### check expect
which expect > /dev/null 2>&1
[[ "$?" != "0" ]] && echo "[ERROR] You don't have expect installed." && exit 1

### Check REMOTE_HOST pingable
case ${_platform} in
    HP-UX)
        ping ${REMOTE_HOST} -n 5 > /dev/null 2>&1;;
    CYGWIN)
        ping -n 5 ${REMOTE_HOST} > /dev/null 2>&1;;
    *)
        ping -c 5 ${REMOTE_HOST} > /dev/null 2>&1;;
esac
[[ "$?" != "0" ]] && printf "[ERROR] ${REMOTE_HOST} is not pingable, please check the given hostname.\n" && exit 1
 

if [[ -s ${ID_RSA} && -s ${ID_RSA_PRIV} ]]; then
    if [[ ${NOKEYGEN} -eq 0 ]]; then
        if ! (_copy_and_verify); then
            if [[ "x" != "x${CLOUD_ENV_VARIABLE}" ]]; then
                echo "[ERROR] Passwordless login verification failed with existing key for cloud"
                exit 1
            fi
            #NOTE: to fix the private key file permission issue,
            # deleting the file here
            rm -f ${ID_RSA} ${ID_RSA_PRIV}
            if ! _keygen; then
                echo "[ERROR] ssh-keygen failed"
                exit 1
            fi
            if ! (_copy_and_verify); then
                echo "[ERROR] Failed to setup passwordless login from $(hostname) to ${REMOTE_HOST}" 
                exit 1
            fi
        fi
    fi
else
    #NOTE: to fix the private key file permission issue,
    # deleting the file here
    rm -f ${ID_RSA} ${ID_RSA_PRIV}
    if ! _keygen; then
        echo "[ERROR] ssh-keygen failed"
        exit 1
    fi
    if ! (_copy_and_verify); then
        echo "[ERROR] Failed to setup passwordless login from $(hostname) to ${REMOTE_HOST}" 
        exit 1
    fi
fi

 

 

