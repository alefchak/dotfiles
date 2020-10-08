#!/bin/bash

echo "Updating packages..."
sudo yum update -y --skip-broken --exclude=kernel*,centos-release*

echo "Installing packages..."
sudo yum downgrade -y code-1.52.1
sudo yum install -y python-pip gitk git-gui sshpass python-devel stow

echo "Installing Tilix..."
cp /etc/yum.conf /tmp/yum.conf
cat <<"EOF" >> /tmp/yum.conf
[ivoarch-Tilix]
name=Copr repo for Tilix owned by ivoarch
baseurl=https://copr-be.cloud.fedoraproject.org/results/ivoarch/Tilix/epel-7-$basearch/
type=rpm-md
skip_if_unavailable=True
gpgcheck=1
gpgkey=https://copr-be.cloud.fedoraproject.org/results/ivoarch/Tilix/pubkey.gpg
repo_gpgcheck=0
enabled=1
enabled_metadata=1
proxy=http://contractorproxyeast.northgrum.com:80/
EOF
sudo yum -c /tmp/yum.conf install -y tilix
rm /tmp/yum.conf

echo "Installing ripgrep..."
cp /etc/yum.conf /tmp/yum.conf
cat <<"EOF" >> /tmp/yum.conf
[carlwgeorge-ripgrep]
name=Copr repo for ripgrep owned by carlwgeorge
baseurl=https://copr-be.cloud.fedoraproject.org/results/carlwgeorge/ripgrep/epel-7-$basearch/
type=rpm-md
skip_if_unavailable=True
gpgcheck=1
gpgkey=https://copr-be.cloud.fedoraproject.org/results/carlwgeorge/ripgrep/pubkey.gpg
repo_gpgcheck=0
enabled=1
enabled_metadata=1
proxy=http://contractorproxyeast.northgrum.com:80/
EOF
sudo yum -c /tmp/yum.conf install -y ripgrep
rm /tmp/yum.conf

if [[ ! -z "$NVM_DIR" ]]; then
    echo "Installing node..."
    git -C "$NVM_DIR" pull || git clone https://github.com/nvm-sh/nvm.git "$NVM_DIR"
    nvm_latest=$(git -C "$NVM_DIR" describe --abbrev=0 --tags --match "v[0-9]*" $(git -C "$NVM_DIR" rev-list --tags --max-count=1))
    git -C "$NVM_DIR" checkout $nvm_latest
    source "$NVM_DIR"/nvm.sh

    # Install latest node lts
    nvm install stable
    nvm use stable
    nvm install-latest-npm

    # Install http-server
    npm install -g http-server
fi

sudo systemctl start docker

echo "Running privileged script..."
script=$(mktemp)
chmod +x $script
cat <<EOF > $script
ln -s /usr/libexec/git-core/git-gui /opt/rh/rh-git29/root/usr/libexec/git-core/git-gui
classic=\$(mktemp)
jq '.hasOverview = true' /usr/share/gnome-shell/modes/classic.json > \$classic
echo \$classic
mv \$classic /usr/share/gnome-shell/modes/classic.json
chmod 666 /usr/share/gnome-shell/modes/classic.json
rm \$classic
EOF

tmux new-session -d 'sudo more /dev/zero'
tmux send-keys '!'$script Enter
sleep 3
tmux kill-session

rm $script
gnome-shell --replace &

echo "Done!"
