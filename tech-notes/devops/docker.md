# Docker

Same for podman just replace `docker` with `podman`

## Stop all running containers

```bash
docker stop $(docker ps -aq)
```

## Remove all containers

```bash
docker rm $(docker ps -aq)
```

## Remove all Docker volumes

```bash
docker volume rm $(docker volume ls -q)
```

## (Optional) Remove all Docker images

```bash
docker rmi $(docker images -q)
```

## Alternatively, to remove all unused Docker data including volumes

```bash
docker system prune --volumes
```