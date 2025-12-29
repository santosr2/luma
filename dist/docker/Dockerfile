# Luma Template Engine - Docker Image
# Official Docker image for Luma
#
# Usage:
#   docker build -t luma/luma:latest -f dist/docker/Dockerfile .
#   docker run luma/luma render template.luma --data-file context.yaml

FROM alpine:3.19

LABEL maintainer="Rubens Santos <rubens@example.com>"
LABEL description="Luma Template Engine - Fast, clean templating with Jinja2 compatibility"
LABEL version="0.1.0-rc.2"

# Install dependencies
RUN apk add --no-cache \
    luajit \
    luajit-dev \
    luarocks5.1 \
    git \
    gcc \
    musl-dev \
    make

# Set working directory
WORKDIR /app

# Copy project files
COPY luma/ /app/luma/
COPY bin/ /app/bin/
COPY cli/ /app/cli/
COPY luma-0.1.0.rockspec /app/
COPY README.md /app/
COPY LICENSE /app/

# Install Luma
RUN luarocks-5.1 make luma-0.1.0.rockspec

# Add luma CLI to PATH
RUN ln -s /app/bin/luma /usr/local/bin/luma \
    && chmod +x /usr/local/bin/luma

# Set default working directory for user templates
WORKDIR /templates

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD luajit -e "require('luma')" || exit 1

# Default command
ENTRYPOINT ["luma"]
CMD ["--help"]

# Examples:
# docker run -v $(pwd):/templates luma/luma render template.luma
# docker run -v $(pwd):/templates luma/luma render template.luma --data-file context.yaml
# docker run -v $(pwd):/templates luma/luma validate template.luma
# docker run -v $(pwd):/templates luma/luma migrate template.j2
