#include "recurrence_engine.h"

namespace alarmmaster {

RecurrenceResult ComputeNextOccurrences(const RecurrenceRequest& request) {
  (void)request;
  static const int64_t kEmpty[1] = {0};
  return RecurrenceResult{.occurrences_epoch_millis = kEmpty, .count = 0};
}

}  // namespace alarmmaster
