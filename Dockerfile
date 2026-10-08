# 前端构建产物由后端同源托管，因此在同一镜像内完成构建
FROM node:22-alpine AS frontend
WORKDIR /build
COPY frontend/package*.json ./
RUN npm config set registry https://registry.npmmirror.com && npm ci
COPY frontend/ ./
RUN npm run build

FROM python:3.13-slim
RUN pip install --no-cache-dir -i https://mirrors.aliyun.com/pypi/simple/ uv

RUN sed -i 's|deb.debian.org|mirrors.aliyun.com|g; s|security.debian.org|mirrors.aliyun.com|g' /etc/apt/sources.list.d/debian.sources 2>/dev/null; \
    sed -i 's|deb.debian.org|mirrors.aliyun.com|g; s|security.debian.org|mirrors.aliyun.com|g' /etc/apt/sources.list 2>/dev/null; \
    apt-get update \
    && apt-get install -y --no-install-recommends fonts-wqy-microhei \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app/backend
ENV UV_COMPILE_BYTECODE=1 UV_LINK_MODE=copy PYTHONPATH=/app/backend UV_INDEX_URL=https://mirrors.aliyun.com/pypi/simple/

COPY backend/pyproject.toml backend/uv.lock ./
RUN uv sync --frozen --all-extras --no-dev

COPY backend/ ./
COPY --from=frontend /build/dist /app/frontend/dist

ENV PATH="/app/backend/.venv/bin:$PATH"
EXPOSE 7302
