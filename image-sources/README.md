# Image Sources

This directory contains the Dockerfile and build assets for creating pre-built container images used by our Dev Container templates.

## Important Note

**These files are NOT part of the Dev Container templates.** They are used solely for building and publishing pre-built images to GitHub Container Registry.

## Structure

```
image-sources/
└── liquescent-devcontainer/
    ├── Dockerfile           # Container definition
    ├── scripts/            # Scripts installed in the image
    └── .dockerignore       # Build exclusions
```

## Building Images

Images are automatically built and published via GitHub Actions when changes are pushed to this directory.

To build locally:

```bash
cd image-sources/liquescent-devcontainer
docker build -t ghcr.io/liquescent-development/liquescent-devcontainer:latest .
```

## Adding New Images

When creating a new template that needs a custom image:

1. Create a new directory under `image-sources/` with the template name
2. Add your Dockerfile and any required assets
3. Update the GitHub Actions workflow if needed
4. The template in `src/<template-name>/` should reference the published image

## Why Separate?

Dev Container templates in `src/` must be self-contained for distribution. By keeping image sources separate:

- Templates remain simple and fast (using pre-built images)
- Users don't need to build images themselves
- We can maintain complex build processes without cluttering templates
- Templates follow the official Dev Container specification