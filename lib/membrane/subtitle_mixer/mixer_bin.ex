defmodule Membrane.SubtitleMixer.MixerBin do
  use Membrane.Bin

  def_input_pad(:video,
    availability: :always,
    demand_unit: :buffers,
    # Here the format is actually what the H264.Payloader accepts
    accepted_format: Membrane.RemoteStream
  )

  def_input_pad(:subtitle,
    availability: :always,
    demand_unit: :buffers,
    accepted_format: Membrane.RemoteStream
  )

  def_output_pad(:output,
    demand_mode: :auto,
    accepted_format: Membrane.H264.RemoteStream
  )

  @impl true
  def handle_init(_ctx, _opts) do
    spec = [
      bin_input(:video)
      |> child(:in_parser, %Membrane.H264.FFmpeg.Parser{
        framerate: nil,
        attach_nalus?: true,
        skip_until_keyframe?: true
      })
      |> child(:payloader, Membrane.MP4.Payloader.H264)
      |> via_in(Pad.ref(:video, 0))
      |> child(:flv_muxer, Membrane.FLV.Muxer),
      bin_input(:subtitle)
      |> via_in(:subtitle)
      |> child(:mixer, Membrane.SubtitleMixer.FLV.Mixer),
      get_child(:flv_muxer)
      |> via_in(:video)
      |> get_child(:mixer)
      |> child(:flv_demuxer, Membrane.FLV.Demuxer)
      |> via_out(Pad.ref(:video, 0))
      |> bin_output()
    ]

    {[spec: spec], %{}}
  end
end
