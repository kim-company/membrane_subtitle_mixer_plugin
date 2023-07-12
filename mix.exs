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
      {:membrane_core, "~> 0.12.1"},
      {:membrane_h264_ffmpeg_plugin, ">= 0.4.1"},
      {:membrane_flv_plugin, ">= 0.7.0"},
      {:membrane_mp4_plugin, ">= 0.25.0"},
      {:membrane_file_plugin, ">= 0.0.0"},
      {:subtitle_mixer, github: "kim-company/subtitle_mixer"}
    ]
  end
end
