defmodule FLV.Tag do
  alias FLV.Tag.Native

  @doc """
  Takes an flv packet and puts a subtitle in it. The output of the native sub
  does NOT match the input Input format: <<prev_size::32, tag_header::88,
  payload>> Output format: <<tag_header::88, payload, payload_size::32>> The
  last 4 bytes of the output have to be split and put in front of the next
  packet.
  """
  def add_caption(payload, text) do
    case Native.add_caption(payload, text) do
      {:ok, data} -> data
      {:error, reason} -> raise inspect(reason)
    end
  end

  def clear_caption(payload) do
    case Native.clear_caption(payload) do
      {:ok, data} -> data
      {:error, reason} -> raise inspect(reason)
    end
  end
end
