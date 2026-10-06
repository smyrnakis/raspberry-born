#!/bin/bash
set -euo pipefail

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
EASYRSA_DIR=/etc/openvpn/server/easy-rsa
PKI_DIR=$EASYRSA_DIR/pki
TLS_CRYPT_KEY=/etc/openvpn/server/tls-crypt.key
EXPORT_DIR=/root/openvpn-client-exports
EXTERNAL_PORT=11194

usage() {
    cat >&2 <<'EOF'
Usage:
  manage-client.sh create NAME
  manage-client.sh create-unattended NAME
  manage-client.sh export NAME
  manage-client.sh list
  manage-client.sh revoke NAME
EOF
    exit 2
}

die() {
    echo "ERROR: $*" >&2
    exit 1
}

require_root() {
    [[ $EUID -eq 0 ]] || die "Run this command with sudo."
}

validate_name() {
    [[ $1 =~ ^[A-Za-z0-9][A-Za-z0-9_-]{0,63}$ ]] \
        || die "NAME must contain only letters, numbers, underscore or hyphen."
    [[ $1 != server ]] || die "The reserved name 'server' cannot be used for a client."
}

read_endpoint() {
    local endpoint
    read -r -p "Public IP address or DDNS name: " endpoint
    [[ $endpoint =~ ^[A-Za-z0-9._-]+$ ]] \
        || die "The endpoint contains unsupported characters."
    printf '%s' "$endpoint"
}

pem_certificate() {
    awk '
        /-----BEGIN CERTIFICATE-----/ { printing=1 }
        printing { print }
        /-----END CERTIFICATE-----/ { exit }
    ' "$1"
}

render_profile() {
    local name=$1 endpoint=$2 profile tmp
    profile=$EXPORT_DIR/$name.ovpn
    tmp=$(mktemp "$EXPORT_DIR/.${name}.XXXXXX")
    trap 'rm -f -- "$tmp"' EXIT

    {
        cat <<EOF
client
dev tun
proto udp
remote $endpoint $EXTERNAL_PORT
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
verify-x509-name server name
tls-version-min 1.2
data-ciphers AES-256-GCM:AES-128-GCM:?CHACHA20-POLY1305
auth SHA256
allow-compression no
explicit-exit-notify 1
verb 3

<ca>
EOF
        pem_certificate "$PKI_DIR/ca.crt"
        cat <<'EOF'
</ca>
<cert>
EOF
        pem_certificate "$PKI_DIR/issued/$name.crt"
        cat <<'EOF'
</cert>
<key>
EOF
        cat "$PKI_DIR/private/$name.key"
        cat <<'EOF'
</key>
<tls-crypt>
EOF
        cat "$TLS_CRYPT_KEY"
        cat <<'EOF'
</tls-crypt>
EOF
    } >"$tmp"

    chmod 600 "$tmp"
    mv -f -- "$tmp" "$profile"
    trap - EXIT
    echo "Created $profile"
}

create_client() {
    local name=$1 unattended=$2 endpoint
    validate_name "$name"
    [[ ! -e $PKI_DIR/issued/$name.crt ]] || die "Certificate already exists: $name"
    [[ ! -e $PKI_DIR/private/$name.key ]] || die "Private key already exists: $name"
    endpoint=$(read_endpoint)

    cd "$EASYRSA_DIR"
    if [[ $unattended == true ]]; then
        ./easyrsa build-client-full "$name" nopass
    else
        ./easyrsa build-client-full "$name"
    fi
    render_profile "$name" "$endpoint"
}

export_client() {
    local name=$1 endpoint
    validate_name "$name"
    [[ -f $PKI_DIR/issued/$name.crt ]] || die "Issued certificate not found: $name"
    [[ -f $PKI_DIR/private/$name.key ]] || die "Private key not found: $name"
    endpoint=$(read_endpoint)
    render_profile "$name" "$endpoint"
}

list_clients() {
    local cert name expiry serial
    shopt -s nullglob
    for cert in "$PKI_DIR"/issued/*.crt; do
        name=${cert##*/}
        name=${name%.crt}
        [[ $name != server ]] || continue
        expiry=$(openssl x509 -in "$cert" -noout -enddate | cut -d= -f2-)
        serial=$(openssl x509 -in "$cert" -noout -serial | cut -d= -f2-)
        printf '%-24s expires=%s serial=%s\n' "$name" "$expiry" "$serial"
    done
}

revoke_client() {
    local name=$1
    validate_name "$name"
    [[ -f $PKI_DIR/issued/$name.crt ]] || die "Issued certificate not found: $name"

    cd "$EASYRSA_DIR"
    ./easyrsa revoke "$name"
    ./easyrsa gen-crl
    install -o root -g root -m 644 "$PKI_DIR/crl.pem" /etc/openvpn/server/crl.pem
    rm -f -- "$EXPORT_DIR/$name.ovpn"
    echo "Revoked $name and updated /etc/openvpn/server/crl.pem"
}

require_root
[[ -x $EASYRSA_DIR/easyrsa ]] || die "Easy-RSA is not installed under $EASYRSA_DIR"
[[ -f $TLS_CRYPT_KEY ]] || die "Missing $TLS_CRYPT_KEY"
install -d -o root -g root -m 700 "$EXPORT_DIR"

case ${1:-} in
    create)
        [[ $# -eq 2 ]] || usage
        create_client "$2" false
        ;;
    create-unattended)
        [[ $# -eq 2 ]] || usage
        create_client "$2" true
        ;;
    export)
        [[ $# -eq 2 ]] || usage
        export_client "$2"
        ;;
    list)
        [[ $# -eq 1 ]] || usage
        list_clients
        ;;
    revoke)
        [[ $# -eq 2 ]] || usage
        revoke_client "$2"
        ;;
    *)
        usage
        ;;
esac
