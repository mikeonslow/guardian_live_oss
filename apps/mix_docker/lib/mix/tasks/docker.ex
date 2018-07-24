defmodule Mix.Tasks.Docker.Init do
  use Mix.Task

  @shortdoc "Initialize distillery release"
  @moduledoc """
  Initialize distillery release.
  Any arguments and options will be passed directly to
  `mix release.init` task.

  This task also create a default `.dockerignore` file.

  ## Examples

      # Use default options
      mix docker.init

      # Pass distillery config
      mix docker.init --name foobar
  """

  defdelegate run(args), to: MixDocker, as: :init
end

defmodule Mix.Tasks.Docker.Build do
  use Mix.Task

  @shortdoc "Build docker image from distillery release"
  @preferred_cli_env :prod
  @moduledoc """
  Build docker image from distillery release.
  Any arguments and options will be passed directly to
  `docker build` command.

  ## Examples

      # Build your app release
      mix docker.build

      # Skip cache
      mix docker.build --no-cache
  """

  defdelegate run(args), to: MixDocker, as: :build
end

defmodule Mix.Tasks.Docker.Release do
  use Mix.Task

  @shortdoc "Build minimal, self-contained docker image"
  @preferred_cli_env :prod
  @moduledoc """
  Build minimal, self-contained docker image
  Any arguments and options will be passed directly to
  `docker build` command.

  ## Examples

      # Build minimal container
      mix docker.release

      # Skip cache
      mix docker.release --no-cache
  """
  defdelegate run(args), to: MixDocker, as: :release
end

defmodule Mix.Tasks.Docker.Copy do
  use Mix.Task

  @shortdoc "Copy release from build image to the local folder"
  @preferred_cli_env :prod
  @moduledoc """
  Copy release tar file from build image to the local folder
  Any arguments and options will be passed directly to
  `docker cp` command.

  ## Examples

  # Build minimal container
  mix docker.copy

  """
  defdelegate run(args), to: MixDocker, as: :copy
end

defmodule Mix.Tasks.Elm.Dev do
  use Mix.Task

  @shortdoc "Rebuild elm for development environment"
  @preferred_cli_env :prod
  @moduledoc """
  Rebuild elm for development environment

  ## Examples

  # Build minimal container
  mix elm.build

  """
  defdelegate run(args), to: MixDocker, as: :elm_build_dev
end

defmodule Mix.Tasks.Elm.Stage do
  use Mix.Task

  @shortdoc "Rebuild elm for staging environment"
  @preferred_cli_env :stage
  @moduledoc """
  Rebuild elm with --production args

  ## Examples

  # Build minimal container
  mix elm.prodbuild

  """
  defdelegate run(args), to: MixDocker, as: :elm_build_stage
end

defmodule Mix.Tasks.Elm.Prod do
  use Mix.Task

  @shortdoc "Rebuild elm for production environment"
  @preferred_cli_env :prod
  @moduledoc """
  Rebuild elm with --production args

  ## Examples

  # Build minimal container
  mix elm.prod

  """
  defdelegate run(args), to: MixDocker, as: :elm_build_prod
end

defmodule Mix.Tasks.Socket.Prod do
  use Mix.Task

  @shortdoc "Change hostname in elm connection file for prod environment"
  @preferred_cli_env :prod
  @moduledoc """
  Change hostname in Connection.elm file to wss://your.prod.server.com

  ## Examples

  # Build minimal container
  mix socket.prod

  """
  defdelegate run(args), to: MixDocker, as: :socket_prod
end

defmodule Mix.Tasks.Socket.Dev do
  use Mix.Task

  @shortdoc "Change hostname in elm connection file for dev environment"
  @preferred_cli_env :dev
  @moduledoc """
  Change hostname in Connection.elm file to ws://localhost:4000

  ## Examples

  # Build minimal container
  mix socket.dev

  """
  defdelegate run(args), to: MixDocker, as: :socket_dev
end

defmodule Mix.Tasks.Socket.Stage do
  use Mix.Task

  @shortdoc "Change hostname in elm connection file for staging environment"
  @preferred_cli_env :stage
  @moduledoc """
  Change hostname in Connection.elm file to wss://your.stage.server.com

  ## Examples

  # Build minimal container
  mix socket.stage

  """
  defdelegate run(args), to: MixDocker, as: :socket_stage
end

defmodule Mix.Tasks.Docker.Publish do
  use Mix.Task

  @shortdoc "Publish current image to docker registry"
  @preferred_cli_env :prod
  @moduledoc """
  Publish current image to docker registry

  ## Examples

      # Just publish
      mix docker.publish

      # Use different tag for published image
      mix docker.publish --tag "mytag-{mix-version}-{git-branch}"
  """
  defdelegate run(args), to: MixDocker, as: :publish
end

defmodule Mix.Tasks.Docker.Shipit do
  use Mix.Task

  @shortdoc "Run build & release & publish"
  @preferred_cli_env :prod
  @moduledoc """
  Run build & release & publis.
  This is the same as running

      mix do docker.build, docker.release, docker.publish

  You can also pass docker build/publish flags.

  ## Examples

      # Use custom --tag (see docker.publish) and --no-cache for docker build
      mix docker.shipit --tag my-custom-tag --no-cache
  """
  defdelegate run(args), to: MixDocker, as: :shipit
end

defmodule Mix.Tasks.Docker.Customize do
  use Mix.Task

  @shortdoc "Copy & customize Dockerfiles"
  @preferred_cli_env :prod
  @moduledoc """
  Copy & customize Dockerfiles
  This task will copy Dockerfile.build and Dockerfile.release
  into project's directory for further customization.
  """

  defdelegate run(args), to: MixDocker, as: :customize
end
