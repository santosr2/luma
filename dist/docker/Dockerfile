# Luma Template Engine - Docker Image
# Official Docker image for Luma
#
# Usage:
#   docker build --build-arg VERSION=0.1.0 -t luma/luma:latest -f dist/docker/Dockerfile .
#   docker run luma/luma render template.luma --data-file context.yaml

FROM alpine:3.19

# Build argument for version
ARG VERSION=0.1.0-rc.2

LABEL maintainer="Rubens Santos <rubens@example.com>"
LABEL description="Luma Template Engine - Fast, clean templating with Jinja2 compatibility"
LABEL version="${VERSION}"

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
COPY LICENSE /app/
COPY README.md /app/

# Generate rockspec dynamically (use scm-1 for pre-releases, VERSION-1 for stable)
RUN ROCKSPEC_VERSION=$(echo "${VERSION}" | grep -q -E '(alpha|beta|rc)' && echo "scm-1" || echo "${VERSION}-1") && \
    cat > /app/luma-${ROCKSPEC_VERSION}.rockspec <<'EOF'
package = "luma"
version = "ROCKSPEC_VERSION_PLACEHOLDER"
source = {
   url = "git+https://github.com/santosr2/luma.git",
   tag = "vVERSION_PLACEHOLDER"
}
description = {
   summary = "A modern template engine for Lua with Jinja2 compatibility",
   detailed = [[
      Luma is a powerful template engine that combines the best of Jinja2's
      syntax with Lua's simplicity and performance. Features include template
      inheritance, filters, macros, loops, and full Jinja2 compatibility mode.
   ]],
   homepage = "https://github.com/santosr2/luma",
   license = "MIT"
}
dependencies = {
   "lua >= 5.1"
}
build = {
   type = "builtin",
   modules = {
      ["luma.init"] = "luma/init.lua",
      ["luma.version"] = "luma/version.lua",
      ["luma.lexer.init"] = "luma/lexer/init.lua",
      ["luma.lexer.inline_detector"] = "luma/lexer/inline_detector.lua",
      ["luma.lexer.jinja"] = "luma/lexer/jinja.lua",
      ["luma.lexer.native"] = "luma/lexer/native.lua",
      ["luma.lexer.tokens"] = "luma/lexer/tokens.lua",
      ["luma.lexer.trim_processor"] = "luma/lexer/trim_processor.lua",
      ["luma.parser.ast"] = "luma/parser/ast.lua",
      ["luma.parser.expressions"] = "luma/parser/expressions.lua",
      ["luma.parser.init"] = "luma/parser/init.lua",
      ["luma.compiler.codegen"] = "luma/compiler/codegen.lua",
      ["luma.compiler.init"] = "luma/compiler/init.lua",
      ["luma.runtime.context"] = "luma/runtime/context.lua",
      ["luma.runtime.init"] = "luma/runtime/init.lua",
      ["luma.runtime.sandbox"] = "luma/runtime/sandbox.lua",
      ["luma.filters.init"] = "luma/filters/init.lua",
      ["luma.utils.compat"] = "luma/utils/compat.lua",
      ["luma.utils.errors"] = "luma/utils/errors.lua",
      ["luma.utils.init"] = "luma/utils/init.lua",
      ["luma.utils.warnings"] = "luma/utils/warnings.lua",
      ["lumacli.init"] = "cli/init.lua",
      ["lumacli.commands.render"] = "cli/commands/render.lua",
      ["lumacli.commands.validate"] = "cli/commands/validate.lua",
      ["lumacli.commands.migrate"] = "cli/commands/migrate.lua",
      ["lumacli.commands.watch"] = "cli/commands/watch.lua",
      ["lumacli.commands.bench"] = "cli/commands/bench.lua"
   },
   install = {
      bin = {
         luma = "bin/luma"
      }
   }
}
EOF
RUN ROCKSPEC_VERSION=$(echo "${VERSION}" | grep -q -E '(alpha|beta|rc)' && echo "scm-1" || echo "${VERSION}-1") && \
    sed -i "s/ROCKSPEC_VERSION_PLACEHOLDER/${ROCKSPEC_VERSION}/g" /app/luma-${ROCKSPEC_VERSION}.rockspec && \
    sed -i "s/VERSION_PLACEHOLDER/${VERSION}/g" /app/luma-${ROCKSPEC_VERSION}.rockspec

# Install Luma
RUN ROCKSPEC_VERSION=$(echo "${VERSION}" | grep -q -E '(alpha|beta|rc)' && echo "scm-1" || echo "${VERSION}-1") && \
    luarocks-5.1 make /app/luma-${ROCKSPEC_VERSION}.rockspec

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
