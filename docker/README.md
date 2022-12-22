# Build notes

Setup buildx builders and build (e.g. https://cloud.google.com/kubernetes-engine/docs/how-to/build-multi-arch-for-arm)

Build and push to registry
```
docker buildx build -f Dockerfile.alpine316 . --push -t gcr.io/edwinchiu/yjit-bench:20221207 --platform linux/arm64,linux/amd64
```

# Running

`docker run --security-opt=seccomp=unconfined gcr.io/edwinchiu/yjit-bench:20221207`
