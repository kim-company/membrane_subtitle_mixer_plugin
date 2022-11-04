defmodule Membrane.SubtitleMixer.MixProject do
  use Mix.Project

  def project do
    [
      app: :membrane_subtitle_mixer_plugin,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:membrane_core, "~> 0.10.2"},
      {:membrane_h264_ffmpeg_plugin, "~> 0.21.5"},
      {:membrane_flv_plugin, "~> 0.3.0"},
      {:membrane_mp4_plugin, "~> 0.16.0"},
      {:membrane_file_plugin, "~> 0.12.0"},
      {:subtitle_mixer, github: "kim-company/subtitle_mixer", branch: "fix/32chars"}
    ]
  end
end
