defmodule Subtitle.WebVTTTest do
  use ExUnit.Case

  alias Subtitle.WebVTT

  describe "unmarshal/1" do
    test "simplest possible" do
      input = """
      WEBVTT

      """

      assert {:ok, %WebVTT{cues: []}} == WebVTT.unmarshal(input)
    end

    test "with header text" do
      # NOTE: this test is just checking that the unmarshaler is not failing
      # when header text is provided -- we're not parsing it at the moment.
      input = """
      WEBVTT - This file has no cues.

      """

      assert {:ok, %WebVTT{cues: []}} == WebVTT.unmarshal(input)
    end

    test "common with header and cues" do
      input = """
      WEBVTT - This file has cues.

      14
      00:01:14.815 --> 00:01:18.114
      - What?
      - Where are we now?

      15
      00:01:18.171 --> 00:01:20.991
      - This is big bat country.

      16
      00:01:21.058 --> 00:01:23.868
      - [ Bats Screeching ]
      - They won't get in your hair. They're after the bugs.
      """

      assert {:ok,
              %WebVTT{
                cues: [
                  %Subtitle.Cue{
                    id: "14",
                    from: WebVTT.timing_to_ms(1, 14, 815),
                    to: WebVTT.timing_to_ms(1, 18, 114),
                    text: ~s/- What?\n- Where are we now?/
                  },
                  %Subtitle.Cue{
                    id: "15",
                    from: WebVTT.timing_to_ms(1, 18, 171),
                    to: WebVTT.timing_to_ms(1, 20, 991),
                    text: ~s/- This is big bat country./
                  },
                  %Subtitle.Cue{
                    id: "16",
                    from: WebVTT.timing_to_ms(1, 21, 58),
                    to: WebVTT.timing_to_ms(1, 23, 868),
                    text:
                      ~s/- [ Bats Screeching ]\n- They won't get in your hair. They're after the bugs./
                  }
                ]
              }} == WebVTT.unmarshal(input)
    end

    test "without cue idenfitiers" do
      input = """
      WEBVTT

      04:02.500 --> 04:05.000
      J'ai commencé le basket à l'âge de 13, 14 ans

      04:05.001 --> 04:07.800
      Sur les <i.foreignphrase><lang en>playground</lang></i>, ici à Montpellier
      """

      assert {:ok,
              %WebVTT{
                cues: [
                  %Subtitle.Cue{
                    id: "",
                    from: WebVTT.timing_to_ms(4, 2, 500),
                    to: WebVTT.timing_to_ms(4, 5, 0),
                    text: ~s/J'ai commencé le basket à l'âge de 13, 14 ans/
                  },
                  %Subtitle.Cue{
                    id: "",
                    from: WebVTT.timing_to_ms(4, 5, 1),
                    to: WebVTT.timing_to_ms(4, 7, 800),
                    text:
                      ~s|Sur les <i.foreignphrase><lang en>playground</lang></i>, ici à Montpellier|
                  }
                ]
              }} == WebVTT.unmarshal(input)
    end

    test "with X-TIMESTAMP-MAP in the header" do
      # See https://datatracker.ietf.org/doc/html/draft-pantos-http-live-streaming-22#section-3.5
      input = """
      WEBVTT
      X-TIMESTAMP-MAP=MPEGTS:181083,LOCAL:00:00:00.000

      00:44:13.215 --> 00:44:17.881
      Deshalb sollte sollten die Empfehlung
      bis Ende März vorgelegt werden.
      """

      assert {:ok,
              %WebVTT{
                cues: [
                  %Subtitle.Cue{
                    id: "",
                    from: WebVTT.timing_to_ms(44, 13, 215),
                    to: WebVTT.timing_to_ms(44, 17, 881),
                    text:
                      ~s/Deshalb sollte sollten die Empfehlung\nbis Ende März vorgelegt werden./
                  }
                ]
              }} == WebVTT.unmarshal(input)
    end

    test "recession#1" do
      input = """
      WEBVTT
      X-TIMESTAMP-MAP=MPEGTS:181083,LOCAL:00:00:00.000
      """

      assert {:ok, %WebVTT{cues: []}} == WebVTT.unmarshal(input)
    end
  end
end
