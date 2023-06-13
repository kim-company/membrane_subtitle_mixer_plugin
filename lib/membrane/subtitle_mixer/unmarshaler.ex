defmodule Membrane.SubtitleMixer.Unmarshaler do
  use Membrane.Filter

  alias Subtitle.WebVTT

  def_input_pad :input,
    demand_mode: :auto,
    demand_unit: :buffers,
    mode: :pull,
    accepted_format: Membrane.RemoteStream

  def_output_pad :output,
    demand_mode: :auto,
    mode: :pull,
    accepted_format: Membrane.RemoteStream

  @impl true
  def handle_init(_ctx, _opts) do
    {[], %{}}
  end

  @impl true
  def handle_process(:input, buffer, _ctx, state) do
    {:ok, %WebVTT{cues: cues}} = WebVTT.unmarshal(buffer.payload)

    actions =
      cues
      |> Enum.map(fn %Subtitle.Cue{from: from, to: to, text: text} ->
        from = Membrane.Time.milliseconds(from)
        to = Membrane.Time.milliseconds(to)

        %Membrane.Buffer{
          pts: from,
          payload: text,
          metadata: %{
            from: from,
            to: to
          }
        }
      end)
      |> Enum.map(fn buffer -> {:buffer, {:output, buffer}} end)

    {actions, state}
  end
end
