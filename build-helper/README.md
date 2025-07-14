# Initalize Workspace Action

[![GitHub Super-Linter](https://github.com/emergentdotorg/maven-release-action/actions/workflows/linter.yml/badge.svg)](https://github.com/super-linter/super-linter)
![CI](https://github.com/emergentdotorg/maven-release-action/actions/workflows/ci.yml/badge.svg)

This action delivers resources to a GitHub action workspace
To learn how this action was built, see
[Creating a Docker container action](https://docs.github.com/en/actions/creating-actions/creating-a-docker-container-action).

## Create Your Own Action


> [!CAUTION]
>
> Make sure to remove or update the [`CODEOWNERS`](./CODEOWNERS) file! For
> details on how to use this file, see
> [About code owners](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners).

## Usage

Here's an example of how to use this action in a workflow file:

```yaml
name: Example Workflow

on:
  workflow_dispatch:
    inputs:
      resources-dest:
        description: Where to put resource files (relative to workspace root).
        required: true
        default: '.mvn/res'
        type: string

jobs:
  deliver-resources:
    name: Deliver Resources
    runs-on: ubuntu-latest

    steps:
      # Change @main to a specific commit SHA or version tag, e.g.:
      # actions/hello-world-docker-action@e76147da8e5c81eaf017dede5645551d4b94427b
      # actions/hello-world-docker-action@v1.2.3
      - name: Deliver Resources
        id: deliver_resources
        uses: emergentdotorg/maven-release-action@main
        with:
          resources-dest: ${{ inputs.resources-dest }}
```

For example workflow runs, check out the
[Actions tab](https://github.com/emergentdotorg/maven-release-action/actions)!
:rocket:

## Inputs

| Input            | Default    | Description                                          |
|------------------|------------|------------------------------------------------------|
| `resources-dest` | `.mvn/res` | The path to where resource files should be delivered |

## Outputs

| Output                | Description                         |
|-----------------------|-------------------------------------|
| `time`                | The time we greeted you             |
| `maven_user_settings` | Path to the maven settings.xml file |

## Test Locally

After you've cloned the repository to your local machine or codespace, you'll
need to perform some initial setup steps before you can test your action.

> [!NOTE]
>
> You'll need to have a reasonably modern version of
> [Docker](https://www.docker.com/get-started/) handy (e.g. docker engine
> version 20 or later).

1. :hammer_and_wrench: Build the container

   Make sure to replace `emergentdotorg/maven-release-action` with an appropriate
   label for your container.

   ```bash
   docker build -t emergentdotorg/maven-release-action .
   ```

1. :white_check_mark: Test the container

   You can pass individual environment variables using the `--env` or `-e` flag.

   ```bash
   $ docker run --env INPUT_RESOURCES_DEST="foo" emergentdotorg/maven-release-action
   ::notice file=entrypoint.sh,line=7::Hello, Mona Lisa Octocat!
   ```

   Or you can pass a file with environment variables using `--env-file`.

   ```bash
   $ echo "INPUT_RESOURCES_DEST=\"foo\"" > ./.env.test

   $ docker run --env-file ./.env.test emergentdotorg/maven-release-action
   ::notice file=entrypoint.sh,line=7::Hello, Mona Lisa Octocat!
   ```
