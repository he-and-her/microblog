defmodule Mix.Tasks.Site.Build do
  use Mix.Task
  @shortdoc "Builds the static site into /_site"

  @posts_dir "posts"
  @out_dir "_site"

  @layout """
  <!doctype html>
    <html>
      <head>
        <meta charset="utf-8" />
        <meta http-equiv='X-UA-Compatible' content='IE=edge;chrome=1' />
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <link rel="icon" href="/favicon.ico">
        <title>thelastinuit's microblog</title>
        <style>
          @import url('https://fonts.googleapis.com/css2?family=IBM+Plex+Mono&display=swap');
            body {
            font-family: 'IBM Plex Mono', monospace;
          }
          body {color: #FFFFFF; background: #000000; max-width: 80ch; margin: 0 auto; text-align: center; display: flex;justify-content: center; }
          a:hover,a:link,a:visited,a:active { text-decoration: none; color: #FFFFFF; }
          table { min-width: 375px; max-width: 375px; border-collapse: separate; border-spacing: 0; }
          thead { min-width: 375px; max-width: 375px; }
          tbody { min-width: 375px; max-width: 375px; }
          thead tr { min-width: 375px; max-width: 375px; }
          tbody tr { min-width: 375px; max-width: 375px; }
          thead th { text-align: left; }
          tbody td { text-align: left; vertical-align: top; }

          .row-toggle, .row-toggle:focus-visible {
            all: unset;
            display: block;
            appearance: none; cursor: pointer;
          }
          .row-toggle .chev { display: inline-block; }
          .row-toggle[aria-expanded="true"] .chev { transform: rotate(90deg); }

          .details-row[hidden] { display: none; }
          .details {
            min-width: 375px; max-width: 375px;
          }
          .nowrap { white-space: nowrap; }
          img { max-width: 375px;}
        </style>
      </head>
      <body>
        <div class="sidebar">
          <div style="display: flex; flex-wrap: wrap;">
            <div class="content flex-column">
              <div>
                <br/>
                <em>
                  If you must inflict <span style="color: #00FF00;">pain</span>,<br/>
                  perhaps I can <span style="color: #00FF00;">endure</span><br/>
                  so others don't <span style="color: #00FF00;">suffer</span><br/>
                </em>
              </div>
              <div>
                <br/>
                <em>
                  <a href="olive-feinberg.asc" alt="public key">
                    <span style="color: #00FF00;">OxF9E4DEDB07B27B36</span>
                  </a>
                </em>
              </div>
              <br />
              <span style="color: #00FF00;">.</span>microblog
              <table role="table">
                <thead>
                  <tr>
                    <th scope="col"></th>
                    <th scope="col"></th>
                    <th scope="col"></th>
                  </tr>
                </thead>
                <tbody>
                  <%= for p <- @posts do %>
                    <tr>
                      <td>
                        <button class="row-toggle" aria-expanded="false" aria-controls="details-<%= p.id %>" id="toggle-<%= p.id %>">
                          <span class="chev">></span>
                        </button>
                      </td>
                      <td class="nowrap"><%= NaiveDateTime.to_string(p.datetime) %></td>
                      <td><%= p.title %></td>
                    </tr>
                    <tr class="details-row" id="details-<%= p.id %>" role="region" aria-labelledby="toggle-<%= p.id %>" hidden>
                      <td colspan="3">
                        <div class="details">
                          <%= p.body_html %>
                        </div>
                      </td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>
          </div>
          <script>
            document.addEventListener('click', function (e) {
              const btn = e.target.closest('.row-toggle');
              if (!btn) return;
              const regionId = btn.getAttribute('aria-controls');
              const region = document.getElementById(regionId);
              if (!region) return;

              const expanded = btn.getAttribute('aria-expanded') === 'true';
              btn.setAttribute('aria-expanded', String(!expanded));
              region.hidden = expanded; // hide if it was expanded
            });

            function setAccordionMode(enabled) {
              if (!enabled) return;
              const buttons = Array.from(document.querySelectorAll('.row-toggle'));
              buttons.forEach(btn => btn.addEventListener('click', () => {
                const currentId = btn.getAttribute('aria-controls');
                buttons.forEach(other => {
                  if (other === btn) return;
                  const id = other.getAttribute('aria-controls');
                  const region = document.getElementById(id);
                  other.setAttribute('aria-expanded', 'false');
                  if (region) region.hidden = true;
                });
              }));
            }
          </script>
        </div>
      </body>
    </html>
  """

  def run(_args) do
    Mix.shell().info("Building table site…")

    File.rm_rf!(@out_dir)
    File.mkdir_p!(@out_dir)

    posts =
      @posts_dir
      |> File.ls!()
      |> Enum.filter(&String.ends_with?(&1, ".md"))
      |> Enum.map(&load_post!/1)
      |> Enum.sort_by(& &1.datetime, {:desc, Date})

    page =
      EEx.eval_string(@layout,
        assigns: [
          title: "microposts",
          posts: posts,
          year: Date.utc_today().year
        ]
      )

    File.write!(Path.join(@out_dir, "index.html"), page)
    Mix.shell().info("Done → #{@out_dir}/index.html")
  end

  defp load_post!(file) do
    path = Path.join(@posts_dir, file)
    raw = File.read!(path)
    {meta, md0} =
      case split_front_matter(raw) do
        {:ok, yaml, body} -> {parse_yaml(yaml), body}
        :no -> {%{}, raw}
      end

    {title, md} =
      case {Map.get(meta, "title"), md0} do
        {nil, body} ->
          case String.split(body, "\n", parts: 2) do
            ["# " <> t | rest] -> {String.trim(t), Enum.join(rest, "\n")}
            _ -> {"(Untitled)", body}
          end

        {t, body} ->
          {to_string(t), body}
      end

    dt =
      cond do
        is_binary(meta["datetime"]) ->
          {:ok, ndt} = NaiveDateTime.from_iso8601(meta["datetime"])
          ndt

        true ->
          case Regex.run(~r/(\d{4}-\d{2}-\d{2})(?:-(\d{2})(\d{2}))?/, file) do
            [_, date_str, hh, mm] when not is_nil(hh) and not is_nil(mm) ->
              NaiveDateTime.from_iso8601!(date_str <> " " <> hh <> ":" <> mm <> ":00")

            [_, date_str] ->
              {:ok, d} = Date.from_iso8601(date_str)
              NaiveDateTime.new!(d, ~T[00:00:00])

            _ ->
              NaiveDateTime.utc_now()
          end
      end

    slug =
      (meta["id"] || title)
      |> String.downcase()
      |> String.replace(~r/[^a-z0-9]+/u, "-")
      |> String.trim("-")

    html = Earmark.as_html!(md)

    %{
      id: slug <> "-" <> NaiveDateTime.to_iso8601(dt),
      title: title,
      datetime: dt,
      body_html: html
    }
  end

  defp split_front_matter(str) do
    case Regex.run(~r/\A---\s*\n([\s\S]*?)\n---\s*\n([\s\S]*)\z/u, str) do
      [_, yaml, body] -> {:ok, yaml, body}
      _ -> :no
    end
  end

  defp parse_yaml(yaml) do
    case YamlElixir.read_from_string(yaml) do
      {:ok, data} -> data
      _ -> %{}
    end
  end
end
