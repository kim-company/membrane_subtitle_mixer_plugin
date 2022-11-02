defmodule Membrane.SubtitleMixer.FLV.Mixer do
  use Membrane.Filter

  require Membrane.Logger

  alias Membrane.Buffer
  alias Subtitle.Cue
  alias SubtitleMixer.FLV

  require Logger

  @flv_footer_size 4

  def_input_pad :video,
    availability: :always,
    demand_unit: :buffers,
    caps: :any

  def_input_pad :subtitle,
    availability: :always,
    demand_unit: :buffers,
    caps: :any

  def_output_pad :output,
    demand_mode: :auto,
    caps: :any

  @impl true
  def handle_init(_opts) do
    {:ok,
     %{
       header_present?: true,
       previous_tag_size: 0,
       partial: <<>>,
       subtitles: [],
       clear_timestamp: 0
     }}
  end

  @impl true
  def handle_demand(_pad, size, :buffers, _ctx, state) do
    {{:ok, demand: {:video, size}, demand: {:subtitle, size}}, state}
  end

  @impl true
  def handle_caps(:video, caps, _ctx, state) do
    {{:ok, [caps: {:output, caps}]}, state}
  end

  def handle_caps(:subtitle, _caps, _ctx, state) do
    {:ok, state}
  end

  @impl true
  def handle_prepared_to_playing(_ctx, state) do
    {{:ok, demand: :video, demand: :subtitle}, state}
  end

  @impl true
  def handle_process(:video, %Buffer{payload: payload}, _ctx, %{header_present?: true} = state) do
    case Membrane.FLV.Parser.parse_header(state.partial <> payload) do
      {:ok, header, rest} ->
        {actions, state} = prepare_to_send(header, state)
        actions = Enum.concat(actions, demand: :video)
        {{:ok, actions}, %{state | partial: rest, header_present?: false}}

      {:error, :not_enough_data} ->
        {{:ok, demand: :video}, %{state | partial: state.partial <> payload}}

      {:error, :not_a_header} ->
        raise "Invalid data detected on the input. Expected Membrane.FLV header"
    end
  end

  @impl true
  def handle_process(:video, %Buffer{payload: payload}, _ctx, %{header_present?: false} = state) do
    case Membrane.FLV.Parser.parse_body(state.partial <> payload) do
      {:ok, frames, rest} ->
        {actions, state} = prepare_to_send(frames, state)
        actions = Enum.concat(actions, demand: :video)
        {{:ok, actions}, %{state | partial: rest}}

      {:error, :not_enough_data} ->
        {{:ok, demand: :video}, %{state | partial: state.partial <> payload}}
    end
  end

  def handle_process(
        :subtitle,
        %Membrane.Buffer{payload: text, metadata: %{from: from, to: to}},
        _ctx,
        %{subtitles: queue} = state
      ) do
    {{:ok, demand: :subtitle},
     %{state | subtitles: queue ++ [%Cue{from: from, to: to, text: text}]}}
  end

  @impl true
  def handle_end_of_stream(:video, _context, state) do
    last = <<state.previous_tag_size::32>>
    {{:ok, buffer: {:output, %Buffer{payload: last}}, end_of_stream: :output}, state}
  end

  def handle_end_of_stream(:subtitle, _context, state) do
    {:ok, state}
  end

  defp prepare_to_send(packets, state) when is_list(packets) do
    {buffers, state} =
      Enum.reduce(packets, {[], state}, fn packet, {buffers, state} ->
        {tag, tag_size} = Membrane.FLV.Serializer.serialize(packet, state.previous_tag_size)

        {tag, state} =
          if packet.type == :video do
            pts = Membrane.Time.milliseconds(packet.pts)

            case maybe_sub(tag, state.previous_tag_size, pts, state) do
              {{tag, tag_size}, state} ->
                {tag, %{state | previous_tag_size: tag_size}}

              {:noop, state} ->
                {tag, %{state | previous_tag_size: tag_size}}
            end
          else
            {tag, %{state | previous_tag_size: tag_size}}
          end

        {[%Buffer{payload: tag} | buffers], state}
      end)

    {[buffer: {:output, Enum.reverse(buffers)}], state}
  end

  defp prepare_to_send(segment, state) do
    {tag, previous_tag_size} = Membrane.FLV.Serializer.serialize(segment, state.previous_tag_size)
    {[buffer: {:output, %Buffer{payload: tag}}], %{state | previous_tag_size: previous_tag_size}}
  end

  defp maybe_sub(
         tag,
         prev_tag_size,
         pts,
         %{subtitles: [%Cue{from: from, to: to, text: text} | tail]} = state
       )
       when from <= pts and pts <= to do
    Logger.debug(
      "Mixing TAG with text: #{inspect(text)}, from: #{inspect(from)}, pts: #{inspect(pts)}"
    )

    {sub(tag, prev_tag_size, text), %{state | subtitles: tail, clear_timestamp: to}}
  end

  defp maybe_sub(tag, prev_tag_size, pts, %{clear_timestamp: cts} = state)
       when cts > 0 and cts <= pts do
    Logger.debug("Clearing TAG: cts: #{inspect(cts)}, pts: #{inspect(pts)}")
    {sub(tag, prev_tag_size, nil), %{state | clear_timestamp: 0}}
  end

  defp maybe_sub(
         tag,
         prev_tag_size,
         pts,
         %{subtitles: [%Cue{to: to, text: text} | tail]} = state
       )
       when to < pts do
    Logger.info(
      "Skipping cue with text: #{inspect(text)}, to: #{inspect(to)}, pts: #{inspect(pts)}: too old"
    )

    maybe_sub(tag, prev_tag_size, pts, %{state | subtitles: tail})
  end

  defp maybe_sub(_tag, _prev_tag_size, _pts, state), do: {:noop, state}

  defp sub(tag, previous_tag_size, text) do
    tag = if is_nil(text), do: FLV.Tag.clear_caption(tag), else: FLV.Tag.add_caption(tag, text)

    n = byte_size(tag) - @flv_footer_size
    <<tag::binary-size(n), _footer::binary-size(@flv_footer_size)>> = tag
    tag = <<previous_tag_size::32, tag::binary>>
    {tag, byte_size(tag) - @flv_footer_size}
  end
end
