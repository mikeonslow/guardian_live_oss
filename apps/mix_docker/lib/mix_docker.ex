defmodule MixDocker do
  require Logger

  @dockerfile_path :code.priv_dir(:mix_docker)
  @dockerfile_build Application.get_env(:mix_docker, :dockerfile_build, "Dockerfile.build")
  @dockerfile_release Application.get_env(:mix_docker, :dockerfile_release, "Dockerfile.release")

  @default_tag_template "{mix-version}.{git-count}-{git-sha}"

  @prod_server "wss://your.prod.server.com"
  @stage_server "wss://your.stage.server.com:8086"
  @dev_server "ws://localhost:4000"

  def init(args) do
    # copy .dockerignore
    unless File.exists?(".dockerignore") do
      File.cp(Path.join([@dockerfile_path, "dockerignore"]), ".dockerignore")
    end

    Mix.Task.run("release.init", args)
  end

  def build(args) do
    with_dockerfile(@dockerfile_build, fn ->
      docker(:build, @dockerfile_build, image(:build), args)
    end)

    Mix.shell().info("Docker image #{image(:build)} has been successfully created")
  end

  def release(args) do
    app = app_name()
    version = app_version() || release_version()

    cid = "mix_docker-#{:rand.uniform(1_000_000)}"

    with_dockerfile(@dockerfile_release, fn ->
      docker(:rm, cid)
      docker(:create, cid, image(:build))

      docker(
        :cp,
        cid,
        "/opt/app/_build/prod/rel/#{app}/releases/#{version}/#{app}.tar.gz",
        "#{app}.tar.gz"
      )

      docker(:rm, cid)
      docker(:build, @dockerfile_release, image(:release), args)
    end)

    Mix.shell().info("Docker image #{image(:release)} has been successfully created")
    Mix.shell().info("You can now test your app with the following command:")
    Mix.shell().info("  docker run -it --rm #{image(:release)} foreground")
  end

  def copy(_args) do
    app = app_name()

    cid = "mix_docker-#{:rand.uniform(1_000_000)}"

    with_dockerfile(@dockerfile_release, fn ->
      docker(:rm, cid)
      docker(:create, cid, image(:build))
      docker(:cp, cid, "/opt/app/_build/prod/rel/#{app}/releases/0.1.0/#{app}.tar.gz", "./")
      docker(:rm, cid)
    end)

    Mix.shell().info("Release #{app}.tar.gz has been copied to the local file system")
  end

  def elm_build_prod(args) do
    replace_server_in_elm_file(@prod_server)
    elm_build(["--production"] ++ args)
  end

  def elm_build_stage(args) do
    replace_server_in_elm_file(@stage_server)
    elm_build(["--production"] ++ args)
  end

  def elm_build_dev(args) do
    replace_server_in_elm_file(@dev_server)
    elm_build(args)
  end

  def socket_prod(_args) do
    replace_server_in_elm_file(@prod_server)
  end

  def socket_stage(_args) do
    replace_server_in_elm_file(@stage_server)
  end

  def socket_dev(_args) do
    replace_server_in_elm_file(@dev_server)
  end

  def elm_build(args) do
    system!("rm", ["-rf", "apps/app_ui/elm/elm-stuff"])
    system_in_work_dir("elm-install", [], "apps/app_ui/elm")
    system_in_work_dir("node", ["node_modules/brunch/bin/brunch", "build"] ++ args, "apps/app_ui")
    report_elm_build_completed(args)
  end

  def publish(args) do
    {opts, args} = extract_opts(args)
    publish(args, opts)
  end

  def publish(args, opts) do
    name = image(make_image_tag(opts[:tag]))

    docker(:tag, image(:release), name)
    docker(:push, name, args)

    Mix.shell().info("Docker image #{name} has been successfully created")
  end

  def shipit(args) do
    {opts, args} = extract_opts(args)

    build(args)
    release(args)
    publish(args, opts)
  end

  def customize([]) do
    try_copy_dockerfile(@dockerfile_build)
    try_copy_dockerfile(@dockerfile_release)
  end

  defp replace_server_in_elm_file(server_name) do
    replace_server_in_elm_file(@prod_server, server_name)
    replace_server_in_elm_file(@stage_server, server_name)
    replace_server_in_elm_file(@dev_server, server_name)
  end

  defp replace_server_in_elm_file(server_name, server_name), do: :ok

  defp replace_server_in_elm_file(from_server_name, to_server_name) do
    replace = "s|#{from_server_name}|#{to_server_name}|g"
    system!("sed", ["-i", "-e", replace, "apps/app_ui/elm/Common/Connection.elm"])
  end

  defp report_elm_build_completed([]) do
    Mix.shell().info("Elm build completed")
  end

  defp report_elm_build_completed(["--production"]) do
    Mix.shell().info("Elm build completed for production")
  end

  defp image(tag) do
    image_name() <> ":" <> to_string(tag)
  end

  defp image_name do
    Application.get_env(:mix_docker, :image) || to_string(app_name())
  end

  defp make_image_tag(tag) do
    template = tag || Application.get_env(:mix_docker, :tag) || @default_tag_template
    Regex.replace(~r/\{([a-z0-9-]+)\}/, template, fn _, x -> tagvar(x) end)
  end

  defp tagvar("mix-version") do
    app_version() || tagvar("rel-version")
  end

  defp tagvar("rel-version") do
    release_version()
  end

  defp tagvar("git-sha"), do: tagvar("git-sha10")

  defp tagvar("git-sha" <> length) do
    {sha, 0} = System.cmd("git", ["rev-parse", "HEAD"])
    String.slice(sha, 0, String.to_integer(length))
  end

  defp tagvar("git-branch") do
    {branch, 0} = System.cmd("git", ["rev-parse", "--abbrev-ref", "HEAD"])
    String.trim(branch)
  end

  defp tagvar("git-count") do
    {count, 0} = System.cmd("git", ["rev-list", "--count", "HEAD"])
    String.trim(count)
  end

  defp tagvar(other) do
    raise "Image tag variable #{other} is not defined"
  end

  # Simple recursive extraction instead of OptionParser to keep other (docker) flags intact
  defp extract_opts(args), do: extract_opts([], args, [])

  defp extract_opts(head, ["--tag", tag | tail], opts),
    do: extract_opts(head, tail, Keyword.put(opts, :tag, tag))

  defp extract_opts(head, [], opts), do: {opts, head}
  defp extract_opts(head, [h | tail], opts), do: extract_opts(head ++ [h], tail, opts)

  defp docker(:cp, cid, source, dest) do
    system!("docker", ["cp", "#{cid}:#{source}", dest])
  end

  defp docker(:build, dockerfile, tag, args) do
    system!("docker", ["build", "-f", dockerfile, "-t", tag] ++ args ++ ["."])
  end

  defp docker(:create, name, image) do
    system!("docker", ["create", "--name", name, image])
  end

  defp docker(:tag, image, tag) do
    system!("docker", ["tag", image, tag])
  end

  defp docker(:push, image, args) do
    system!("docker", ["push"] ++ args ++ [image])
  end

  defp docker(:rm, cid) do
    system("docker", ["rm", "-f", cid])
  end

  defp with_dockerfile(name, fun) do
    if File.exists?(name) do
      fun.()
    else
      try do
        copy_dockerfile(name)
        fun.()
      after
        File.rm(name)
      end
    end
  end

  defp copy_dockerfile(name) do
    app = app_name()

    content =
      [@dockerfile_path, name]
      |> Path.join()
      |> File.read!()
      |> String.replace("${APP}", to_string(app))

    File.write!(name, content)
  end

  defp try_copy_dockerfile(name) do
    if File.exists?(name) do
      Logger.warn("#{name} already exists")
    else
      copy_dockerfile(name)
    end
  end

  defp system_in_work_dir(cmd, args, work_dir) do
    Mix.shell().info("$ #{cmd} #{args |> Enum.join(" ")}")
    Logger.debug("$ #{cmd} #{args |> Enum.join(" ")}")
    System.cmd(cmd, args, into: IO.stream(:stdio, :line), cd: work_dir)
  end

  defp system(cmd, args) do
    Mix.shell().info("$ #{cmd} #{args |> Enum.join(" ")}")
    Logger.debug("$ #{cmd} #{args |> Enum.join(" ")}")
    System.cmd(cmd, args, into: IO.stream(:stdio, :line))
  end

  defp system!(cmd, args) do
    ## {_, 0} =
    system(cmd, args)
  end

  defp app_name do
    release_name_from_cwd = File.cwd!() |> Path.basename() |> String.replace("-", "_")
    Mix.Project.get().project[:app] || release_name_from_cwd
  end

  defp app_version do
    Mix.Project.get().project[:version]
  end

  defp release_version do
    {:ok, rel} = Mix.Releases.Release.get(:default)
    rel.version
  end
end
