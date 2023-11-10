# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Luca Colagrande <colluca@iis.ee.ethz.ch>

TARGET ?= all
SELECT_RUNTIME ?= rtl

ifeq ($(SELECT_RUNTIME), banshee)
RUNTIME = runtime/banshee
else ifeq ($(SELECT_RUNTIME), rtl-no-fesvr)
RUNTIME = runtime/rtl-no-fesvr
else
RUNTIME = runtime/rtl
endif

SUBDIRS = runtime/banshee runtime/rtl math runtime/rtl-no-fesvr apps tests

.PHONY: all $(SUBDIRS)

all: $(SUBDIRS)

# Explicit dependency of apps on runtime
apps: $(RUNTIME) math
	$(MAKE) -C $@ TARGET=$(TARGET)

# Explicit dependency of tests on runtime
tests: $(RUNTIME) math
	$(MAKE) -C $@ $(TARGET)

runtime/rtl runtime/rtl-no-fesvr runtime/banshee math:
	$(MAKE) -C $@ $(TARGET)
