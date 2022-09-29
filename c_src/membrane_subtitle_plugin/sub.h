#pragma once
#include <stdint.h>
#include "flv.h"

void flv_payload_read_tag(uint8_t *data, flvtag_t *tag);

#include "_generated/sub.h"
