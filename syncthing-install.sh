curl -s https://syncthing.net/release-key.txt | sudo apt-key add -
echo "deb http://apt.syncthing.net/ syncthing release" | sudo tee /etc/apt/sources.list.d/syncthing.list
apt-get update
apt-get install syncthing
useradd -r syncthing -m -d /home/syncthing
systemctl enable syncthing@syncthing.service
systemctl start syncthing@syncthing.service


echo `[Service]
ExecStart=
ExecStart=-/usr/bin/syncthing -no-browser -no-restart -logflags=0 -gui-address=http://10.0.1.1:8384` 
EDITOR=vi systemctl edit syncthing@syncthing.service
