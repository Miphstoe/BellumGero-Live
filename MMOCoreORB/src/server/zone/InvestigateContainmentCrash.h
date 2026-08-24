/*
 * TEMPORARY diagnostic instrumentation for the "buildings appearing at 0,0
 * after crash" investigation (branch: investigate-building-containment-crash).
 *
 * This header exists solely to gate a handful of targeted log statements
 * added to confirm/deny whether a player being inside a Cell at shutdown/
 * crash time correlates with a Building/Cell losing its persisted zone.
 *
 * To remove this instrumentation: delete this file and the 4 guarded
 * blocks that #include it (grep for INVESTIGATE_CONTAINMENT_CRASH_LOGGING),
 * or revert the commit that introduced them.
 */

#ifndef INVESTIGATECONTAINMENTCRASH_H_
#define INVESTIGATECONTAINMENTCRASH_H_

#define INVESTIGATE_CONTAINMENT_CRASH_LOGGING 1

#endif // INVESTIGATECONTAINMENTCRASH_H_
