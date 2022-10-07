defmodule Membrane.Subtitle.MixerBin do
  use Membrane.Bin

  def_input_pad(:video,
    availability: :always,
    demand_unit: :buffers,
    caps: :any
  )

  def_input_pad(:subtitle,
    availability: :always,
    demand_unit: :buffers,
    caps: :any
  )

  def_output_pad(:output,
    demand_mode: :auto,
    caps: :any
  )

  @impl true
  def handle_init(_opts) do
    spec = %ParentSpec{
      children: [
        in_parser: %Membrane.H264.FFmpeg.Parser{
          framerate: nil,
          attach_nalus?: true,
          skip_until_keyframe?: true
        },
        payloader: Membrane.MP4.Payloader.H264,
        flv_muxer: Membrane.FLV.Muxer,
        mixer: Membrane.Subtitle.Mixer,
        flv_demuxer: Membrane.FLV.Demuxer,
        out_parser: %Membrane.H264.FFmpeg.Parser{
          framerate: nil,
          alignment: :au,
          attach_nalus?: true,
          skip_until_keyframe?: true
        }
      ],
      links: [
        link_bin_input(:video)
        |> to(:in_parser)
        |> to(:payloader)
        |> via_in(Pad.ref(:video, 0))
        |> to(:flv_muxer),
        link_bin_input(:subtitle)
        |> via_in(:subtitle)
        |> to(:mixer),
        link(:flv_muxer)
        |> via_in(:video)
        |> link(:mixer)
        |> to(:flv_demuxer)
        |> via_out(Pad.ref(:video, 0))
        |> to(:out_parser)
        |> to_bin_output()
      ]
    }

    {{:ok, spec: spec}, %{}}
  end
end
