defmodule Membrane.SubtitleMixer.UnmarshalerTest do
  use ExUnit.Case
  use Membrane.Pipeline
  import Membrane.Testing.Assertions

  alias Membrane.Testing
  alias Membrane.SubtitleMixer

  test "sends one buffer for each cue found in input" do
    vtt = """
    WEBVTT

    00:01.000 --> 00:04.000
    - Never drink liquid nitrogen.

    00:05.000 --> 00:09.000
    - It will perforate your stomach.
    - You could die.
    """

    links = [
      child(:source, %Testing.Source{output: [vtt]})
      |> child(:unmarshaler, SubtitleMixer.Unmarshaler)
      |> child(:sink, Testing.Sink)
    ]

    pid = Membrane.Testing.Pipeline.start_link_supervised!(structure: links)

    assert_sink_buffer(pid, :sink, %Membrane.Buffer{
      payload: ~s/- Never drink liquid nitrogen./,
      pts: 1_000_000_000,
      metadata: %{
        from: 1_000_000_000,
        to: 4_000_000_000
      }
    })

    assert_sink_buffer(pid, :sink, %Membrane.Buffer{
      payload: ~s/- It will perforate your stomach.\n- You could die./,
      pts: 5_000_000_000,
      metadata: %{
        from: 5_000_000_000,
        to: 9_000_000_000
      }
    })

    Testing.Pipeline.terminate(pid, blocking?: true)
  end
end
