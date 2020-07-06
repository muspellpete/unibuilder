defmodule UnibuilderWeb.PageController do
  use UnibuilderWeb, :controller

  @doc """
  Handles showing the index page when the build is done.
  """
  def index(conn, %{"built" => built, "build_path" => build_path})
      when built == "built" and build_path != "" do
    name = get_name_from(build_path)
    # remove the executable file from path to get the folder
    containing_folder = String.replace(build_path, name <> ".exe", "")
    IO.puts("Zipping in folder: " <> containing_folder <> " after removing name: " <> name)

    files =
      File.ls!(containing_folder)
      |> Enum.map(&String.to_charlist/1)

      #cwd specifies that we are working within a directory, which then is removed from the final file
    {:ok, {zipped_file_name, zipped_file_binary}} = :zip.create(name <> ".zip", files, [:memory, {:cwd, containing_folder}])

    IO.puts("Done zipping")
    send_download(conn, {:binary, zipped_file_binary}, filename: zipped_file_name)
  end

  @doc """
  Handles showing the index page when the parameter specifies that it has cloned successfully.
  """
  def index(conn, %{"cloned" => cloned, "path" => path}) when cloned == "cloned" and path != "" do
    name = get_name_from(path)

    build_path = "D:/UnityBuilds/Build/" <> name <> "/" <> name <> ".exe"

    case run_build(path, build_path) do
      {:ok, _} ->
        render(conn, "built.html", build_path: build_path, name: name)

      {:error, reason} ->
        render(conn, "failed.html", reason: reason, url: "N/A")
    end
  end

  @doc """
  Handles showing the index page when there is a reason for failure present.
  """
  def index(conn, %{"url" => url, "reason" => reason}) when url != "" and reason != "" do
    render(conn, "index.html", placeholder: url)
  end

  @doc """
  Handles showing the index page when there is a build url present.
  This will redirect the user to either the cloned page or the failed page depending on the build outcom.
  """
  def index(conn, %{"url" => url}) when url != "" do
    IO.puts("Beginning build of " <> url)
    update_repository(conn, url, "D:/UnityBuilds/Repository/" <> get_name_from(url))
  end

  @doc """
  Handles showing the index page initially, when there are no url parameters present, meaning
  that this is the start of a session.
  """
  def index(conn, _params) do
    render(conn, "index.html", placeholder: "https://github.com/muspellpete/bob")
  end

  @doc """
  Gets the title of the page.
  """
  def get_title(placeholder) do
    if String.length(placeholder) > 0 do
      # failed on: " <> placeholder
      "Unity builder"
    else
      "Unity builder"
    end
  end

  defp get_name_from(path) when path != nil and path != "" do
    case Regex.run(~r/.*[\/|\\]([A-Za-z]*)(\.git|\.exe)?$/, path) do
      hits when hits != nil ->
        Enum.at(hits, 1, "unnamed")

      nil ->
        "unnamed"
    end
  end

  defp run_build(path, build_path) do
    {_, code} =
      System.cmd("C:/Program Files/Unity/Hub/Editor/2019.3.0f3/Editor/Unity.exe", [
        "-batchmode",
        "-nographics",
        "-projectPath",
        path,
        "-logFile",
        "-",
        "-buildWindowsPlayer",
        build_path,
        "-quit"
      ])

    case code do
      1 ->
        {:error, "Failed to build"}

      _ ->
        {:ok, ""}
    end
  end

  defp update_repository(conn, url, path) do
    unless File.exists?(path) do
      File.mkdir_p(path)
    end

    with {:ok, repository} <- repo_is_ok(Git.new(path)),
         {:ok, _} <- Git.status(repository),
         {:ok, output} <- Git.ls_remote(repository),
         {:ok, _} <- has_url(output, url),
         {:ok, _} <- Git.clean(repository, "-f"),
         {:ok, _} <- Git.pull(repository) do
      IO.puts("Successfully pulled repository")
      render(conn, "cloned.html", url: url, path: repository.path)
    else
      _error ->
        IO.puts("Failed to update repository, will clone new to path: " <> path)
        File.rm_rf(path)

        case Git.clone([url, path]) do
          {:ok, repo} ->
            render(conn, "cloned.html", url: url, path: repo.path)

          {:error, reason} ->
            render(conn, "failed.html", url: url, reason: reason.message)
        end
    end
  end

  defp repo_is_ok(repo) do
    case repo do
      nil ->
        {:error, "Repo is nil"}

      _ ->
        {:ok, repo}
    end
  end

  defp has_url(output, url) do
    if output =~ url do
      {:ok, ""}
    else
      {:error, "File does not contain url"}
    end
  end
end
