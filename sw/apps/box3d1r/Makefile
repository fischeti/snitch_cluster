# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Luca Colagrande <colluca@iis.ee.ethz.ch>

# Usage of absolute paths is required to externally include this Makefile
MK_DIR   := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
DATA_DIR := $(realpath $(MK_DIR)/data)
SRC_DIR  := $(realpath $(MK_DIR)/src)

DATA_CFG ?= $(DATA_DIR)/params.json
SECTION  ?=

APP     ?= box3d1r
SRCS    ?= $(realpath $(SRC_DIR)/main.c)
INCDIRS ?= $(dir $(DATA_H)) $(SRC_DIR)

DATAGEN_PY = $(MK_DIR)/scripts/datagen.py
DATA_H    ?= $(DATA_DIR)/data.h

$(dir $(DATA_H)):
	mkdir -p $@

$(DATA_H): $(DATAGEN_PY) $(DATA_CFG) | $(dir $(DATA_H))
	$< -c $(DATA_CFG) --section="$(SECTION)" > $@

.PHONY: clean-data clean

clean-data:
	rm -f $(DATA_H)

clean: clean-data
