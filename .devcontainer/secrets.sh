#!/bin/sh
#######################################################################
#
#   FileName:   secrets.sh
#
#######################################################################

config='
[
    {
        "secret": "SSH_PRIVATE_KEY_GITHUB",
        "file": "/home/codespace/.ssh/id_ed25519",
        "field": ".[0].notes",
        "owner": "codespace:codespace",
        "mode": "400"
    },
    {
        "secret": "SSH_PUBLIC_KEY_GITHUB",
        "file": "/home/codespace/.ssh/id_ed25519.pub",
        "field": ".[0].notes",
        "owner": "codespace:codespace",
        "mode": "400"
    }
]
'

bwLogin() {
    case $(bw status | jq .status) in
        '"locked"' ) action='unlock';;
        '"unlocked"' ) action='nothing';;
        '"unauthenticated"' ) action='login';;
        *) action='login';;
    esac

    if [ "${action}" != 'nothing' ]
    then
        test=1
        attempt=0
        until [ $test -eq 0 ]
        do
            attempt=$(expr $attempt + 1)
            # echo "test: attempt=${attempt}"
            if [ $attempt -gt 3 ]
            then
                echo "Error: To many tries on password, to retry run ${0}"
                exit 1
            fi
            res=$(bw $action --raw)
            test=$?
        done
        export BW_SESSION="${res}"
    fi
}

bwSetSecrets() {
    length=$(echo $config | jq 'length')
    for i in $(seq 1 ${length})
    do
        # echo "index=${i}"
        index=$(expr $i-1)
        file=$(echo $config | jq ".[$index].file" | sed 's/"//g')
        if [ ! -s "${file}" ]
        then
            envvar=$(echo $config | jq ".[$index].env_var" | sed 's/"//g')
            secret=$(echo $config | jq ".[$index].secret" | sed 's/"//g')
            field=$(echo $config | jq ".[$index].field" | sed 's/"//g')
            mode=$(echo $config | jq ".[$index].mode" | sed 's/"//g')
            bwLogin
            if [ "${envvar}" != "null" ]
            then
                echo "export $envvar=$(bw list items --search "${secret}" | jq "${field}" | sed 's/"//g')" > $file
            else
                echo "$(bw list items --search "${secret}" | jq "${field}" | sed 's/"//g')" > $file
            fi
            chmod $mode $file
        fi
    done

}

############################## SCRIPT ##############################
mkdir -p ~/.env
chmod 700 ~/.env

bwSetSecrets

unset BW_SESSION

echo 'if [ -f ~/.env/* ] ; then for file in ~/.env/* ; do . $file ; done ; fi' >> ~/.bashrc

### End of File