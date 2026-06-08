FROM ubuntu:24.04

RUN yes | unminimize && \
    apt-get install -y openssh-server && \
    rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash boundary-user

RUN mkdir /var/run/sshd && \
    sed -i 's/#Port 22/Port 2222/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PermitTTY yes/PermitTTY yes/' /etc/ssh/sshd_config && \
    echo "TrustedUserCAKeys /etc/ssh/trusted-user-ca-keys.pem" >> /etc/ssh/sshd_config && \
    echo "AllowTcpForwarding yes" >> /etc/ssh/sshd_config && \
    echo "PermitTTY yes" >> /etc/ssh/sshd_config

EXPOSE 2222

CMD ["/usr/sbin/sshd", "-D", "-e"]
