#!/usr/bin/pwsh

###### Functions/Aliases ######
function install-bitwarden() {
    $URL="https://vault.bitwarden.com/download/?app=cli&platform=linux&_gl=1*n7eskc*_gcl_au*MTIzOTY5NTgwMS4xNzI5OTIxNzA1"

    sudo apt-get update
    sudo apt-get install -y unzip

    # Set up some directories to avoid warnings
    mkdir -p "$($HOME)/.config/Bitwarden CLI"
    touch "$($HOME)/.config/Bitwarden CLI/data.json"

    if ( -not ( test-path -type leaf /usr/local/bin/bw ) ) {
        write-output "Download BitWarden Zip"
        wget "$($URL)" --quiet -O /tmp/bw.zip

        write-output "Install BitWarden"
        unzip /tmp/bw.zip
        sudo mv -f ./bw /usr/local/bin/bw

        write-output "Clean Up BitWarden Install"
        rm -f /tmp/bw.zip
    }
}


###### Secrets ######
function config-secrets() {
    #### CONFIG ####
    $secrets=@(
        @{
            secret='SSH_PRIVATE_KEY_GITHUB'
            file="/home/codespace/.ssh/id_ed25519"
            owner="codespace:codespace"
            field="[0].notes"
            mode="400"
        },
        @{
            secret='SSH_PUBLIC_KEY_GITHUB'
            file="/home/codespace/.ssh/id_ed25519.pub"
            owner="codespace:codespace"
            mode="400"
        }
    )

    #### SCRIPT ####
    $bwStatus=bw status | convertfrom-json

    if ( @("unauthenticated","locked") -contains $bwStatus.status ) {
        # 3 attempts to login before fail
        $maxAttempts=3
        $attempt=0
        do {
            $attempt++
            $env:BW_SESSION=bw login --raw
        } until ( $env:BW_SESSION -or $attempt -gt $maxAttempts )
    }

    if ( "$($env:BW_SESSION)".length -ne 0 ) {
        # bw sync
        $secrets | foreach-object {
            if ( $_.file ) {
                if ( -not ( test-path -type leaf $_.file ) ) {
                    (bw list items --search $_.secret | convertfrom-json)[0].notes | out-file -encoding ascii "$($_.file)"
                    if ( $_.file_mode ) {
                        $mode=$_.file_mode
                    } else {
                        $mode="400"
                    }
                    chmod $mode $_.file
                    chown $_.owner $_.file
                }
            } elseif ( $_.env_var ) {
                $secret=(bw list items --search $_.secret | convertfrom-json)
                $_.field -split '\.' | foreach {
                    $secret=$secret.($_)
                }
                Set-Item -Path "Env:$($_.env_var)" -Value $secret
            }
            # else {
            #     write-warning "File Exists: $($_.file)"
            # }
        }
    } else {
        write-error "No BitWarden Login - secrets not set up"
    }
}

function update-pip() {
    write-output "################ Pip Update"
    python3 -m pip install --upgrade pip

    if ( Test-Path -Type Leaf ./requirements.txt ) {
        write-output "################ pip install -r ./requirements.txt"
        cat ./requirements.txt
        pip install -r ./requirements.txt
    }
}

########################## SCRIPT ##########################

sudo chown 1000:1000 /data/

if ( Test-Path ./.devcontainer/profiles.yml ) {
    mkdir -p "$($HOME)/.dbt"
    ln -sf (get-item ./.devcontainer/profiles.yml).FullName "$($HOME)/.dbt/profiles.yml"
}

if ( Test-Path ./.devcontainer/pwsh_profile.ps1 ) {
    mkdir -p "$($HOME)/.config/powershell"
    ln -sf (get-item ./.devcontainer/pwsh_profile.ps1).FullName "$($PROFILE)"
}


# Pip Updates & Installs
update-pip

if ( ! $env:PROJECT_GH_WORKFLOW ) {
    install-bitwarden
    # config-secrets
}

### End of File