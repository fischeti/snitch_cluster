// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include <snrt.h>
#include "printf.h"

#define TRANSFER_SIZE 4096
#define NUM_TRANSFERS 16
#define WIDE_WORD_SIZE 64
#define PAGE_SIZE 4096
#define READ_TRANSFER 1
#define NUM_ITER 2
#define NUMX 3
#define NUMY 8
#define NUM_HBM_CHANNELS 8
// #define BENCH_HBM_L1_SINGLE_CH
// #define BENCH_HBM_L1_ALL_CH
// #define BENCH_L1_L1
// #define BENCH_L1_L1_NEIGHBOR
// #define BENCH_L1_L1_MAX_DIST
// #define BENCH_BW_HBM_ALL_CH
#define BENCH_BW_HBM_SINGLE_CH

uint64_t l3_alloc_ptr;

typedef struct xy_coord {
  uint32_t x;
  uint32_t y;
} xy_coord_t;

xy_coord_t cluster_xy_coord(uint32_t cluster_id) {
  xy_coord_t idx;
  idx.x = cluster_id / NUMY;
  idx.y = cluster_id % NUMY;
  return idx;
}

uint64_t hbm_channel_offset(uint32_t channel) {
  return 0x80000000 + (uint64_t)channel * 0x40000000;
}

int main() {

  // We don't need the computation cores for this benchmark
  if (!snrt_is_dm_core()) {
    return 0;
  }

  snrt_barrier_t *barrier = (void *)0x0fffff00;

  uint32_t core_global_id = snrt_global_core_idx();
  uint32_t core_global_num = snrt_global_core_num();
  uint32_t core_id = snrt_cluster_core_idx();
  uint32_t core_num = snrt_cluster_core_num();
  uint32_t cluster_id = snrt_cluster_idx();
  uint32_t cluster_num = snrt_cluster_num();
  xy_coord_t coord = cluster_xy_coord(cluster_id);

  // Allocate memory
  // Pointer to local TCDM
  uint64_t l1_ptr = (uint64_t)snrt_l1alloc(TRANSFER_SIZE);
  // Pointer to TCDM of neighbor cluster
  uint64_t l1_ptr2 = l1_ptr + SNRT_CLUSTER_OFFSET;
  // Pointer to TCDM of not so neighbor cluster
  uint64_t l1_ptr3 = l1_ptr + cluster_base_offset(cluster_id) + cluster_base_offset(cluster_num - 1);
  // Pointer to L3
  if (cluster_id == 0) {
    // Reset the barrier
    barrier->cnt = 0;
    barrier->iteration = 0;
    l3_alloc_ptr = ALIGN_UP((uint64_t)snrt_l3alloc(TRANSFER_SIZE + PAGE_SIZE - 1), PAGE_SIZE);
  }
  // Initialize with zero to get rid of assertions
  snrt_dma_start_1d_wideptr(l1_ptr, (uint64_t)snrt_zero_memory_ptr(cluster_id), TRANSFER_SIZE);
  snrt_dma_wait_all();

  // Synchronize all DM cores
  snrt_partial_barrier(barrier, cluster_num);

// Transfering 1KB of data from L3 to L1
#ifdef BENCH_HBM_L1_SINGLE_CH
  for (int c = 0; c < cluster_num; c++) {
    #pragma clang loop unroll(disable)
    for (int i = 0; i < NUM_HBM_CHANNELS; i++) {
      uint64_t hbm_ch_ptr = l3_alloc_ptr - hbm_channel_offset(0) + hbm_channel_offset(i);
      if (c == cluster_id) {
        snrt_mcycle();
  #if READ_TRANSFER
        snrt_dma_start_1d_wideptr(l1_ptr, hbm_ch_ptr, TRANSFER_SIZE);
  #else
        snrt_dma_start_1d_wideptr(hbm_ch_ptr, l1_ptr, TRANSFER_SIZE);
  #endif
        snrt_dma_wait_all();
        snrt_mcycle();
      }
      snrt_partial_barrier(barrier, cluster_num);
    }
  }
#endif

// Transfering 1KB of data from L3 to L1
#ifdef BENCH_HBM_L1_ALL_CH
  #pragma clang loop unroll(disable)
  for (int i = 0; i < NUM_ITER; i++) {
    xy_coord_t coord = cluster_xy_coord(cluster_id);
    uint64_t l3_ch_ptr = l3_alloc_ptr - hbm_channel_offset(0) + hbm_channel_offset(coord.y);
    snrt_mcycle();
  #if READ_TRANSFER
    snrt_dma_start_1d_wideptr(l1_ptr, l3_ch_ptr, TRANSFER_SIZE);
  #else
    snrt_dma_start_1d_wideptr(l3_ch_ptr, l1_ptr, TRANSFER_SIZE);
  #endif
    snrt_dma_wait_all();
    snrt_mcycle();
  }
#endif


// Transfering 1KB of data from L1 to L1 of all other clusters
#ifdef BENCH_L1_L1
  if (cluster_id == 0) {
    for (int c = 0; c < cluster_num; c++) {
      uint64_t l1_ptr_c = l1_ptr + c * SNRT_CLUSTER_OFFSET;
      snrt_mcycle();
#if READ_TRANSFER
      snrt_dma_start_1d_wideptr(l1_ptr, l1_ptr_c, TRANSFER_SIZE);
#else
      snrt_dma_start_1d_wideptr(l1_ptr_c, l1_ptr, TRANSFER_SIZE);
#endif
      snrt_dma_wait_all();
      snrt_mcycle();
    }
  }
#endif

// Transfering 1KB of data from L1 to L1 of neighbor cluster
#ifdef BENCH_L1_L1_NEIGHBOR
  if (cluster_id == 0) {
    snrt_mcycle();
#if READ_TRANSFER
    snrt_dma_start_1d_wideptr(l1_ptr, l1_ptr2, TRANSFER_SIZE);
#else
    snrt_dma_start_1d_wideptr(l1_ptr2, l1_ptr, TRANSFER_SIZE);
#endif
    snrt_dma_wait_all();
    snrt_mcycle();
  }
#endif

// Transfering 1KB of data from L1 to L1 of maximum distance cluster
#ifdef BENCH_L1_L1_MAX_DIST
  if (cluster_id == 0) {
    snrt_mcycle();
#if READ_TRANSFER
    snrt_dma_start_1d_wideptr(l1_ptr, l1_ptr3, TRANSFER_SIZE);
#else
    snrt_dma_start_1d_wideptr(l1_ptr3, l1_ptr, TRANSFER_SIZE);
#endif
    snrt_dma_wait_all();
    snrt_mcycle();
  }
#endif

#ifdef BENCH_BW_HBM_ALL_CH
  uint32_t hbm_channel_id = cluster_xy_coord(cluster_id).y;
  uint64_t hbm_ch_ptr = l3_alloc_ptr - hbm_channel_offset(0) + hbm_channel_offset(hbm_channel_id);
  snrt_mcycle();
  #pragma clang loop unroll(disable)
  for (int i = 0; i < NUM_TRANSFERS; i++) {
#if READ_TRANSFER
    snrt_dma_start_1d_wideptr(l1_ptr, hbm_ch_ptr, TRANSFER_SIZE);
#else
    snrt_dma_start_1d_wideptr(hbm_ch_ptr, l1_ptr, TRANSFER_SIZE);
#endif
  }
  snrt_dma_wait_all();
  snrt_mcycle();
#endif

#ifdef BENCH_BW_HBM_SINGLE_CH
  if (coord.x == 0 && coord.y == 4) {
    uint64_t hbm_ch_ptr = l3_alloc_ptr - hbm_channel_offset(0) + hbm_channel_offset(coord.y);
    snrt_mcycle();
    #pragma clang loop unroll(disable)
    for (int i = 0; i < NUM_TRANSFERS; i++) {
#if READ_TRANSFER
     snrt_dma_start_1d_wideptr(l1_ptr, hbm_ch_ptr, TRANSFER_SIZE);
#else
      snrt_dma_start_1d_wideptr(hbm_ch_ptr, l1_ptr, TRANSFER_SIZE);
#endif
    }
    snrt_dma_wait_all();
    snrt_mcycle();
  }
#endif
    return 0;
}
