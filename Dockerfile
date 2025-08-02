# Simple K6 Runner with Web Dashboard Support
FROM grafana/k6:latest

# No additional packages needed - K6 handles HTML reports natively
USER root

# Create directories for mounting
RUN mkdir -p /scripts /reports /output && \
    chown -R k6:k6 /scripts /reports /output

# Copy simple entrypoint
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Set working directory
WORKDIR /scripts

# Use k6 user
USER k6

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD []