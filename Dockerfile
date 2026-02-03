FROM rockylinux/rockylinux:9
LABEL maintainer="tdockendorf@osc.edu; johrstrom@osc.edu"

# setup the ondemand repositories
RUN dnf -y install https://yum.osc.edu/ondemand/4.0/ondemand-release-web-4.0-1.el9.noarch.rpm

# install all the dependencies
RUN dnf -y update && \
    dnf install -y dnf-utils epel-release ondemand-dex && \
    dnf module enable -y ruby:3.3 nodejs:20 && \
    dnf install -y ondemand && \
    dnf clean all && rm -rf /var/cache/dnf/*

# Generate SSL certificate
RUN /usr/libexec/httpd-ssl-gencerts

# Copy your custom config file
COPY config/ood_portal.yml /etc/ood/config/ood_portal.yml

# Run the update script
RUN /opt/ood/ood-portal-generator/sbin/update_ood_portal

# Expose ports
EXPOSE 80 443

# Start Apache directly
CMD ["/usr/sbin/httpd", "-D", "FOREGROUND"]
