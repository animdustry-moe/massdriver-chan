defmodule Massdriver.Commit do
  use Committee
  # import Committee.Helpers, only: [staged_files: 0, staged_files: 1]

  def pre_commit do
    label = :"[.committee.exs]"
    IO.puts("#{label} Verifying integrity of database migration files...")
    {changes, _} = System.cmd("git", [
      "diff",
      "--cached",
      "--diff-filter=ac",         # Excluding Added and Copied.
      "--name-only"
    ])

    if String.contains?(changes, "priv/database/migrations/") do
      {:halt, "#{label} Migration files must not be edited or deleted after creation, check your Git status!"}
    end
  end

  # Here's where you can add your Git hooks!
  #
  # To abort a commit, return in the form of `{:halt, reason}`.
  # To print a success message, return in the form of `{:ok, message}`.
  #
  # ## Example:
  #
  #   @impl true
  #   @doc """
  #   This function auto-runs `mix format` on staged files.
  #   """
  #   def pre_commit do
  #     System.cmd("mix", ["format"] ++ staged_files([".ex", ".exs"]))
  #     System.cmd("git", ["add"] ++ staged_files())
  #   end
  #
  # If you want to test your example manually, you can run:
  #
  #   `mix committee.runner [pre_commit | post_commit]`
  #
end
