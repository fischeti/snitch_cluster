// Copyright 2024 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Jayanth Jonnalagadda <jjonnalagadd@student.ethz.ch>
// Luca Colagrande <colluca@iis.ee.ethz.ch>

#include "snrt.h"

#include "box3d1r.h"
#include "data.h"

int main() {
    double *local_A, *local_A_, *local_c;
    double *remote_A, *remote_A_, *remote_c;

    remote_A = A;
    remote_A_ = A_;
    remote_c = c;

    // Allocate space in TCDM
    local_A = (double *)snrt_l1_next();
    local_c = local_A + nx * ny * nz;
    local_A_ = local_c + (2 * r + 1) * (2 * r + 1) * (2 * r + 1);

    // Copy data in TCDM
    if (snrt_is_dm_core()) {
        size_t size_A = nx * ny * nz * sizeof(double);
        size_t size_c =
            (2 * r + 1) * (2 * r + 1) * (2 * r + 1) * sizeof(double);
        snrt_dma_start_1d(local_A, remote_A, size_A);
        snrt_dma_start_1d(local_c, remote_c, size_c);
        snrt_dma_wait_all();
    }
    snrt_cluster_hw_barrier();

    // printf("1. Address of A[0]: %p\n", (void*)&local_A[0]);

    // Compute
    if (snrt_cluster_core_idx() == 0) {
        // printf("2. Address of A[0]: %p\n", (void*)&local_A[0]);
        box3d1r(r, nx, ny, nz, local_c, local_A, local_A_);
    }
    snrt_cluster_hw_barrier();

    // Copy data out of TCDM
    if (snrt_is_dm_core()) {
        size_t size_A_ = nx * ny * nz * sizeof(double);
        snrt_dma_start_1d(remote_A_, local_A_, size_A_);
        snrt_dma_wait_all();
    }
    snrt_cluster_hw_barrier();

    return 0;
}