FROM python:3.10-slim

ARG VERSION
ENV PYTHONUNBUFFERED=1 \
    APP_VERSION=${VERSION} \
    PYTHONPATH=/app

WORKDIR /app/

# Install uv
# Ref: https://docs.astral.sh/uv/guides/integration/docker/#installing-uv
COPY --from=ghcr.io/astral-sh/uv:0.5.11 /uv /uvx /bin/

# Place executables in the environment at the front of the path
# Ref: https://docs.astral.sh/uv/guides/integration/docker/#using-the-environment
ENV PATH="/app/.venv/bin:$PATH"

# Compile bytecode
# Ref: https://docs.astral.sh/uv/guides/integration/docker/#compiling-bytecode
ENV UV_COMPILE_BYTECODE=1

# uv Cache
# Ref: https://docs.astral.sh/uv/guides/integration/docker/#caching
ENV UV_LINK_MODE=copy

# Create non-root user and install curl for healthcheck
RUN useradd --create-home appuser && \
    apt-get update && \
    apt-get install -y curl && \
    rm -rf /var/lib/apt/lists/*

# Copy dependency files
COPY ./pyproject.toml ./uv.lock /app/

# Install dependencies
# Ref: https://docs.astral.sh/uv/guides/integration/docker/#intermediate-layers
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --frozen --no-install-project

# Copy application code
COPY main.py /app/

# Set permissions
RUN chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Add labels for better container management
LABEL org.opencontainers.image.source="https://github.com/chirilac/primer-task-ci" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.description="FastAPI application for Primer task"

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=3s \
    CMD curl -f http://localhost:8000/health || exit 1

# Run with uvicorn
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "4"]
