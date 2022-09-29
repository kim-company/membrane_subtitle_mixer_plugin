defmodule Membrane.Subtitle.BundlexProject do
  use Bundlex.Project

  def project do
    [
      natives: natives()
    ]
  end

  defp natives() do
    [
      sub: [
        interface: :nif,
        sources: ["sub.c", "mpeg.c", "caption.c", "cea708.c", "eia608_charmap.c", "eia608.c", "scc.c", "utf8.c", "xds.c", "_eia608_from_utf8.c", "flv.c"],
        compiler_flags: ["-g"],
        preprocessor: Unifex
      ]
    ]
  end
end
