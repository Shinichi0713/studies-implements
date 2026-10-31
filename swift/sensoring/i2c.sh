sudo raspi-config
# Interface Options → I2C → Enable
sudo reboot

# Raspberry Pi OS (64bit) の場合
wget https://download.swift.org/swift-5.10.1-release/ubuntu2204-aarch64/swift-5.10.1-RELEASE/swift-5.10.1-RELEASE-ubuntu22.04-aarch64.tar.gz
tar xzf swift-5.10.1-RELEASE-ubuntu22.04-aarch64.tar.gz
sudo mv swift-5.10.1-RELEASE-ubuntu22.04-aarch64 /opt/swift
echo 'export PATH=/opt/swift/usr/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

