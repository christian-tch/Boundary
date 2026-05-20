FROM alpine:3.19

# Install dependencies
RUN apk add --no-cache \
    ca-certificates \
    curl \
    unzip \
    su-exec \
    dumb-init

# Download Boundary Enterprise binary
ARG BOUNDARY_VERSION=0.21.3+ent
RUN cd /tmp && \
    curl -fsSL "https://releases.hashicorp.com/boundary/${BOUNDARY_VERSION}/boundary_${BOUNDARY_VERSION}_linux_amd64.zip" -o boundary.zip && \
    unzip boundary.zip && \
    mv boundary /usr/local/bin/ && \
    chmod +x /usr/local/bin/boundary && \
    rm boundary.zip

# Create boundary user
RUN addgroup -g 1000 boundary && \
    adduser -D -u 1000 -G boundary boundary

USER boundary

ENTRYPOINT ["/usr/bin/dumb-init", "--", "boundary"]
CMD ["server", "-config", "/boundary/config.hcl"]
