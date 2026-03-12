#pragma once

#include <stdint.h>

namespace alarmmaster {

struct RecurrenceRequest {
  int32_t type;
  int32_t interval;
  int32_t limit;
  int64_t anchor_epoch_millis;
  int64_t now_epoch_millis;
};

struct RecurrenceResult {
  const int64_t* occurrences_epoch_millis;
  int32_t count;
};

// Sprint 5 seam only: implementation is optional and not used as runtime owner.
RecurrenceResult ComputeNextOccurrences(const RecurrenceRequest& request);

}  // namespace alarmmaster
