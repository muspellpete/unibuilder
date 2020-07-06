defmodule UnibuilderWeb.PageController do
  use UnibuilderWeb, :controller

  def index(conn, %{"url" => url}) when url != "" do
    IO.puts("Beginning build of " <> url)
    hits = Regex.run(~r/.*\/([A-Za-z]*)(\.git)?$/, url)
    update_repository(conn, url, "D:/UnityBuilds/Repository/" <> Enum.at(hits, 1, "unnamed"))
  end

  def index(conn, %{"url" => url, "reason" => reason}) when url != "" and reason != "" do
    render(conn, "index.html", placeholder: url, reason: reason)
  end

  def index(conn, _params) do
    render(conn, "index.html", placeholder: "https://github.com/muspellpete/bob")
  end

  def get_title(placeholder) do
    if String.length(placeholder) > 0 do
      # failed on: " <> placeholder
      "Unity builder"
    else
      "Unity builder"
    end
  end

  defp update_repository(conn, url, path) do
    unless File.exists?(path) do
      File.mkdir(path)
    end

    with {:ok, repository} <- repo_is_ok(Git.new(path)),
         {:ok, _} <- Git.status(repository),
         {:ok, output} <- Git.ls_remote(repository),
         {:ok, _} <- has_url(output, url),
         {:ok, _} <- Git.clean(repository, "-f"),
         {:ok, _} <- Git.pull(repository) do
      IO.puts("Successfully pulled repository")
      render(conn, "cloned.html", url: url)
    else
      _error ->
        IO.puts("Failed to update repository, will clone new to path: " <> path)
        File.rm_rf(path)

        case Git.clone([url, path]) do
          {:ok, _repo} ->
            render(conn, "cloned.html", url: url)

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
