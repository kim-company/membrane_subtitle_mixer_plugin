#include "sub.h"
#include <string.h>
#include <stdio.h>

#define PREV_SIZE_HEADER 4

UNIFEX_TERM add_caption(UnifexEnv *env, UnifexPayload *flv, char *text)
{
    // init
    flvtag_t tag;
    UnifexPayload payload;
    flvtag_init(&tag);

    // put payload data in the tag excluding the first 4 bytes
    // to respect the internal tag format
    flv_payload_read_tag(&flv->data[PREV_SIZE_HEADER], &tag);

    // check if the tag is writable
    if (flvtag_avcpackettype_nalu == flvtag_avcpackettype(&tag))
        flvtag_addcaption_text(&tag, text);

    // allocate and write the output payload
    size_t size = flvtag_raw_size(&tag);
    unifex_payload_alloc(env, UNIFEX_PAYLOAD_BINARY, size, &payload);
    memcpy(payload.data, flvtag_raw_data(&tag), size);

    flvtag_free(&tag);
    return add_caption_result_ok(env, &payload);
}

UNIFEX_TERM clear_caption(UnifexEnv *env, UnifexPayload *flv)
{
    return add_caption(env, flv, NULL);
}

void flv_payload_read_tag(uint8_t *data, flvtag_t *tag)
{
    uint32_t size;
    // bytes 6, 7, 8 of a tag header contain the tag size
    size = ((data[1] << 16) | (data[2] << 8) | data[3]);
    flvtag_reserve(tag, size);

    // copy the payload
    memcpy(tag->data, data, size + FLV_TAG_HEADER_SIZE);

    // write the last 4 bytes which are outside of the input payload
    flvtag_updatesize(tag, size);
}

void handle_destroy_state(UnifexEnv *env)
{
    UNIFEX_UNUSED(env);
}
