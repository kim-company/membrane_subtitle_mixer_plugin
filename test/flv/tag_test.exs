defmodule FLV.TagTest do
  use ExUnit.Case

  test "benchmark" do
    tag = File.read!("test/fixtures/h264.tag")

    Benchee.run(
      %{
        "add_caption" => fn -> FLV.Tag.add_caption(tag, "Hello") end
      },
      memory_time: 2
    )
  end
end
