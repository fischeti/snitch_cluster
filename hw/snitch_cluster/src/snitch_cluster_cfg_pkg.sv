// Copyright 2025 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Snitch Cluster Configuration Package
//
// Defines the `snitch_cluster_cfg_t` configuration struct and a `DefaultCfg`
// localparam. This replaces the JSON-based clustergen configuration system,
// following the Cheshire-style config struct pattern.

package snitch_cluster_cfg_pkg;

  ///////////////////////
  //  Parameterization //
  ///////////////////////

  // Maximum bounds for fixed-size arrays in the config struct.
  // Unused entries must be zero.
  localparam int unsigned MaxCoresWidth    = 5;  // up to 32 cores
  localparam int unsigned MaxHivesWidth    = 3;  // up to 8 hives
  localparam int unsigned MaxSsrsWidth     = 3;  // up to 8 SSRs per core
  localparam int unsigned MaxCachedRegions = 4;

  ////////////////////
  //  Sub-structs   //
  ////////////////////

  // Per-core configuration (includes embedded SSR configs)
  typedef struct packed {
    // ISA standard extensions
    bit RVE;
    bit RVF;
    bit RVD;
    // ISA custom extensions
    bit XDivSqrt;
    bit XF16;
    bit XF16ALT;
    bit XF8;
    bit XF8ALT;
    bit XFVEC;
    bit XFDOTP;
    bit Xdma;
    bit Xssr;
    bit Xfrep;
    bit Xcopift;
    bit Xpulppostmod;
    bit Xpulpabs;
    bit Xpulpbitop;
    bit Xpulpbr;
    bit Xpulpclip;
    bit Xpulpmacsi;
    bit Xpulpminmax;
    bit Xpulpslet;
    bit Xpulpvect;
    bit Xpulpvectshufflepack;
    bit PrivateIpu;
    // Per-core micro-architecture parameters
    int unsigned NumIntOutstandingLoads;
    int unsigned NumIntOutstandingMem;
    int unsigned NumFPOutstandingLoads;
    int unsigned NumFPOutstandingMem;
    int unsigned NumDTLBEntries;
    int unsigned NumITLBEntries;
    int unsigned NumSequencerInstr;
    int unsigned NumSequencerLoops;
    int unsigned NumSsrs;
    int unsigned SsrMuxRespDepth;
    // Hive assignment
    bit [MaxHivesWidth-1:0] Hive;
    // SSR configurations (MaxSsrs slots; unused entries are zero)
    snitch_ssr_pkg::ssr_cfg_t [2**MaxSsrsWidth-1:0] SsrCfgs;
    // SSR FP register indices (SSR i uses FP register SsrRegs[i])
    bit [4:0] [2**MaxSsrsWidth-1:0] SsrRegs;
  } core_cfg_t;

  // Per-hive instruction cache configuration
  typedef struct packed {
    int unsigned LineWidth;    // in bits (e.g. 512)
    int unsigned LineCount;    // number of lines per way
    int unsigned Ways;
    bit          L1TagScm;
    bit          L1DataScm;
  } icache_cfg_t;

  // FPU timing/latency configuration (cluster-wide)
  typedef struct packed {
    int unsigned             LatCompFp32;
    int unsigned             LatCompFp64;
    int unsigned             LatCompFp16;
    int unsigned             LatCompFp16Alt;
    int unsigned             LatCompFp8;
    int unsigned             LatCompFp8Alt;
    int unsigned             LatNoncomp;
    int unsigned             LatConv;
    int unsigned             LatSdotp;
    fpnew_pkg::pipe_config_t PipeConfig;
  } fpu_timing_cfg_t;

  // TCDM configuration
  typedef struct packed {
    int unsigned       Size;              // in kB
    int unsigned       Banks;
    int unsigned       HyperBanks;
    snitch_pkg::topo_e Topology;
    int unsigned       Radix;
    int unsigned       NumSwitchNets;
    bit                SwitchLfsrArbiter;
  } tcdm_cfg_t;

  // Timing pipeline register insertion knobs
  typedef struct packed {
    bit                         RegisterOffloadReq;
    bit                         RegisterOffloadRsp;
    bit                         RegisterCoreReq;
    bit                         RegisterCoreRsp;
    bit                         RegisterTCDMCuts;
    bit                         RegisterExtWide;
    bit                         RegisterExtNarrow;
    bit                         RegisterExpNarrow;
    bit                         RegisterFPUReq;
    bit                         RegisterFPUIn;
    bit                         RegisterFPUOut;
    bit                         RegisterDcaReq;
    bit                         RegisterDcaRsp;
    bit                         RegisterSequencer;
    bit                         IsoCrossing;
    axi_pkg::xbar_latency_e     NarrowXbarLatency;
    axi_pkg::xbar_latency_e     WideXbarLatency;
  } timing_cfg_t;

  // PMA cached region
  typedef struct packed {
    bit [63:0] Base;
    bit [63:0] Mask;
  } pma_region_t;

  /////////////////////////////
  //  Main config struct     //
  /////////////////////////////

  typedef struct packed {
    // Cluster identity & placement
    bit [63:0]  ClusterBaseAddr;
    bit [63:0]  ClusterBaseOffset;
    int unsigned BaseHartId;

    // Address & data widths
    int unsigned AddrWidth;
    int unsigned NarrowDataWidth;
    int unsigned WideDataWidth;

    // AXI ID widths
    int unsigned NarrowIdWidthIn;
    int unsigned WideIdWidthIn;

    // Atomics / collectives
    int unsigned AtomicIdWidth;
    int unsigned CollectiveWidth;

    // Core & hive counts
    int unsigned NrCores;
    int unsigned NrHives;

    // Memory subsystem
    tcdm_cfg_t   Tcdm;
    int unsigned ClusterPeriphSize;  // in kB
    int unsigned ZeroMemorySize;     // in kB
    int unsigned ExtMemorySize;      // in kB
    int unsigned BootRomSize;        // in kB

    // DMA
    int unsigned DmaNumAxInFlight;
    int unsigned DmaReqFifoDepth;
    int unsigned DmaNumChannels;
    int unsigned NumExpWideTcdmPorts;

    // Outstanding transactions
    int unsigned NarrowTrans;
    int unsigned WideTrans;

    // Feature flags
    bit     VMSupport;
    bit     EnableDebug;
    bit     EnableXif;
    bit     EnableDca;
    bit     EnableNarrowCollectives;
    bit     EnableWideCollectives;
    bit     AliasRegionEnable;
    bit     IntBootromEnable;
    bit     SramCfgExpose;
    bit     ClusterBaseExpose;
    bit     EnableExternalInterrupts;
    bit     NarrowAxiPortExpose;

    // XIF parameters
    int unsigned XifIdWidth;
    bit [31:0]   XifMisa;

    // Boot & alias
    bit [31:0]   BootAddr;
    bit [63:0]   AliasRegionBase;

    // CAQ
    int unsigned CaqDepth;
    int unsigned CaqTagWidth;

    // DCA
    int unsigned DcaDataWidth;

    // FPU timing (cluster-wide)
    fpu_timing_cfg_t FpuTiming;

    // Pipeline register timing knobs
    timing_cfg_t Timing;

    // Per-hive configuration (fixed-size array)
    icache_cfg_t [2**MaxHivesWidth-1:0] Hives;

    // Per-core configuration (fixed-size array; unused entries are zero)
    core_cfg_t [2**MaxCoresWidth-1:0] Cores;

    // PMA cached regions
    int unsigned NrCachedRegions;
    pma_region_t [MaxCachedRegions-1:0] CachedRegions;
  } snitch_cluster_cfg_t;

  ////////////////////////
  //  Helper functions  //
  ////////////////////////

  // Compute TCDM depth (words per bank)
  function automatic int unsigned get_tcdm_depth(snitch_cluster_cfg_t cfg);
    return cfg.Tcdm.Size * 1024 / (cfg.Tcdm.Banks * (cfg.NarrowDataWidth / 8));
  endfunction

  // Compute narrow AXI output ID width
  function automatic int unsigned get_narrow_id_width_out(snitch_cluster_cfg_t cfg);
    localparam int unsigned NrNarrowMasters = 3;
    return $clog2(NrNarrowMasters) + cfg.NarrowIdWidthIn;
  endfunction

  // Compute wide AXI output ID width
  function automatic int unsigned get_wide_id_width_out(snitch_cluster_cfg_t cfg);
    int unsigned nr_wide_masters;
    nr_wide_masters = 1 + cfg.DmaNumChannels + cfg.NrHives;
    return $clog2(nr_wide_masters) + cfg.WideIdWidthIn;
  endfunction

  // Compute PMA configuration from cached regions
  function automatic snitch_pma_pkg::snitch_pma_t gen_pma_cfg(snitch_cluster_cfg_t cfg);
    automatic snitch_pma_pkg::snitch_pma_t pma = '0;
    pma.NrCachedRegionRules = cfg.NrCachedRegions;
    for (int i = 0; i < cfg.NrCachedRegions; i++) begin
      pma.CachedRegion[i].base = cfg.CachedRegions[i].Base[47:0];
      pma.CachedRegion[i].mask = cfg.CachedRegions[i].Mask[47:0];
    end
    return pma;
  endfunction

  // Generate FPU implementation for a given core
  function automatic fpnew_pkg::fpu_implementation_t gen_fpu_impl(
    snitch_cluster_cfg_t cfg, int unsigned core_idx
  );
    automatic fpnew_pkg::fpu_implementation_t impl;
    automatic fpu_timing_cfg_t t = cfg.FpuTiming;
    automatic core_cfg_t c = cfg.Cores[core_idx];

    // PipeRegs
    impl.PipeRegs = '{
      // FMA
      '{int'(t.LatCompFp32), int'(t.LatCompFp64), int'(t.LatCompFp16),
        int'(t.LatCompFp8), int'(t.LatCompFp16Alt), int'(t.LatCompFp8Alt)},
      // DIVSQRT
      '{1, 1, 1, 1, 1, 1},
      // NONCOMP
      '{int'(t.LatNoncomp), int'(t.LatNoncomp), int'(t.LatNoncomp),
        int'(t.LatNoncomp), int'(t.LatNoncomp), int'(t.LatNoncomp)},
      // CONV
      '{int'(t.LatConv), int'(t.LatConv), int'(t.LatConv),
        int'(t.LatConv), int'(t.LatConv), int'(t.LatConv)},
      // DOTP
      '{int'(t.LatSdotp), int'(t.LatSdotp), int'(t.LatSdotp),
        int'(t.LatSdotp), int'(t.LatSdotp), int'(t.LatSdotp)}
    };

    // UnitTypes
    impl.UnitTypes = '{
      // FMA - always MERGED
      '{fpnew_pkg::MERGED, fpnew_pkg::MERGED, fpnew_pkg::MERGED,
        fpnew_pkg::MERGED, fpnew_pkg::MERGED, fpnew_pkg::MERGED},
      // DIVSQRT - MERGED if XDivSqrt, else DISABLED
      '{c.XDivSqrt ? fpnew_pkg::MERGED : fpnew_pkg::DISABLED,
        c.XDivSqrt ? fpnew_pkg::MERGED : fpnew_pkg::DISABLED,
        c.XDivSqrt ? fpnew_pkg::MERGED : fpnew_pkg::DISABLED,
        c.XDivSqrt ? fpnew_pkg::MERGED : fpnew_pkg::DISABLED,
        c.XDivSqrt ? fpnew_pkg::MERGED : fpnew_pkg::DISABLED,
        c.XDivSqrt ? fpnew_pkg::MERGED : fpnew_pkg::DISABLED},
      // NONCOMP - always PARALLEL
      '{fpnew_pkg::PARALLEL, fpnew_pkg::PARALLEL, fpnew_pkg::PARALLEL,
        fpnew_pkg::PARALLEL, fpnew_pkg::PARALLEL, fpnew_pkg::PARALLEL},
      // CONV - always MERGED
      '{fpnew_pkg::MERGED, fpnew_pkg::MERGED, fpnew_pkg::MERGED,
        fpnew_pkg::MERGED, fpnew_pkg::MERGED, fpnew_pkg::MERGED},
      // DOTP - MERGED if XFDOTP, else DISABLED
      '{c.XFDOTP ? fpnew_pkg::MERGED : fpnew_pkg::DISABLED,
        c.XFDOTP ? fpnew_pkg::MERGED : fpnew_pkg::DISABLED,
        c.XFDOTP ? fpnew_pkg::MERGED : fpnew_pkg::DISABLED,
        c.XFDOTP ? fpnew_pkg::MERGED : fpnew_pkg::DISABLED,
        c.XFDOTP ? fpnew_pkg::MERGED : fpnew_pkg::DISABLED,
        c.XFDOTP ? fpnew_pkg::MERGED : fpnew_pkg::DISABLED}
    };

    impl.PipeConfig = t.PipeConfig;
    return impl;
  endfunction

  // Extract per-core bit vector for a given single-bit field.
  // Returns bit[i] = field value of core i, for i in [0, NrCores).
  `define SNITCH_CFG_GET_CORE_BITS(FIELD) \
  function automatic bit [2**MaxCoresWidth-1:0] get_``FIELD(snitch_cluster_cfg_t cfg); \
    automatic bit [2**MaxCoresWidth-1:0] result = '0; \
    for (int i = 0; i < cfg.NrCores; i++) result[i] = cfg.Cores[i].FIELD; \
    return result; \
  endfunction

  `SNITCH_CFG_GET_CORE_BITS(RVE)
  `SNITCH_CFG_GET_CORE_BITS(RVF)
  `SNITCH_CFG_GET_CORE_BITS(RVD)
  `SNITCH_CFG_GET_CORE_BITS(XDivSqrt)
  `SNITCH_CFG_GET_CORE_BITS(XF16)
  `SNITCH_CFG_GET_CORE_BITS(XF16ALT)
  `SNITCH_CFG_GET_CORE_BITS(XF8)
  `SNITCH_CFG_GET_CORE_BITS(XF8ALT)
  `SNITCH_CFG_GET_CORE_BITS(XFVEC)
  `SNITCH_CFG_GET_CORE_BITS(XFDOTP)
  `SNITCH_CFG_GET_CORE_BITS(Xdma)
  `SNITCH_CFG_GET_CORE_BITS(Xssr)
  `SNITCH_CFG_GET_CORE_BITS(Xfrep)
  `SNITCH_CFG_GET_CORE_BITS(Xcopift)
  `SNITCH_CFG_GET_CORE_BITS(Xpulppostmod)
  `SNITCH_CFG_GET_CORE_BITS(Xpulpabs)
  `SNITCH_CFG_GET_CORE_BITS(Xpulpbitop)
  `SNITCH_CFG_GET_CORE_BITS(Xpulpbr)
  `SNITCH_CFG_GET_CORE_BITS(Xpulpclip)
  `SNITCH_CFG_GET_CORE_BITS(Xpulpmacsi)
  `SNITCH_CFG_GET_CORE_BITS(Xpulpminmax)
  `SNITCH_CFG_GET_CORE_BITS(Xpulpslet)
  `SNITCH_CFG_GET_CORE_BITS(Xpulpvect)
  `SNITCH_CFG_GET_CORE_BITS(Xpulpvectshufflepack)
  `SNITCH_CFG_GET_CORE_BITS(PrivateIpu)

  // Extract per-core byte-valued fields as a packed byte array.
  // Returns result[i] = field value of core i, for i in [0, NrCores).
  `define SNITCH_CFG_GET_CORE_BYTES(FIELD) \
  function automatic bit [7:0] [2**MaxCoresWidth-1:0] get_``FIELD(snitch_cluster_cfg_t cfg); \
    automatic bit [7:0] [2**MaxCoresWidth-1:0] result = '0; \
    for (int i = 0; i < cfg.NrCores; i++) result[i] = bit'(cfg.Cores[i].FIELD); \
    return result; \
  endfunction

  `SNITCH_CFG_GET_CORE_BYTES(NumIntOutstandingLoads)
  `SNITCH_CFG_GET_CORE_BYTES(NumIntOutstandingMem)
  `SNITCH_CFG_GET_CORE_BYTES(NumFPOutstandingLoads)
  `SNITCH_CFG_GET_CORE_BYTES(NumFPOutstandingMem)
  `SNITCH_CFG_GET_CORE_BYTES(NumDTLBEntries)
  `SNITCH_CFG_GET_CORE_BYTES(NumITLBEntries)
  `SNITCH_CFG_GET_CORE_BYTES(NumSequencerInstr)
  `SNITCH_CFG_GET_CORE_BYTES(NumSequencerLoops)
  `SNITCH_CFG_GET_CORE_BYTES(NumSsrs)
  `SNITCH_CFG_GET_CORE_BYTES(SsrMuxRespDepth)
  `SNITCH_CFG_GET_CORE_BYTES(Hive)

  ////////////////
  //  Defaults  //
  ////////////////

  // SSR configs for compute cores (3 SSRs, all with intersection / indirection)
  localparam snitch_ssr_pkg::ssr_cfg_t ComputeSsr0 = '{  // Intersection slave
    Indirection:       1,
    IsectMaster:       0,
    IsectMasterIdx:    0,
    IsectSlave:        1,
    IsectSlaveSpill:   1,
    IndirOutSpill:     1,
    NumLoops:          4,
    IndexWidth:        17,
    PointerWidth:      17,
    ShiftWidth:        3,
    RptWidth:          4,
    IndexCredits:      3,
    IsectSlaveCredits: 8,
    DataCredits:       4,
    MuxRespDepth:      3
  };

  localparam snitch_ssr_pkg::ssr_cfg_t ComputeSsr1 = '{  // Intersection master (idx=1)
    Indirection:       1,
    IsectMaster:       1,
    IsectMasterIdx:    1,
    IsectSlave:        0,
    IsectSlaveSpill:   1,
    IndirOutSpill:     1,
    NumLoops:          4,
    IndexWidth:        17,
    PointerWidth:      17,
    ShiftWidth:        3,
    RptWidth:          4,
    IndexCredits:      3,
    IsectSlaveCredits: 8,
    DataCredits:       4,
    MuxRespDepth:      3
  };

  localparam snitch_ssr_pkg::ssr_cfg_t ComputeSsr2 = '{  // Intersection master (idx=0)
    Indirection:       1,
    IsectMaster:       1,
    IsectMasterIdx:    0,
    IsectSlave:        0,
    IsectSlaveSpill:   1,
    IndirOutSpill:     1,
    NumLoops:          4,
    IndexWidth:        17,
    PointerWidth:      17,
    ShiftWidth:        3,
    RptWidth:          4,
    IndexCredits:      3,
    IsectSlaveCredits: 8,
    DataCredits:       4,
    MuxRespDepth:      3
  };

  // SSR FP register indices for compute cores: SSR 0→FP reg 0, 1→1, 2→2
  // Positional order for bit [4:0][7:0]: index [7] first (MSB), [0] last (LSB)
  localparam bit [4:0][2**MaxSsrsWidth-1:0] ComputeSsrRegs =
    {5'd0, 5'd0, 5'd0, 5'd0, 5'd0, 5'd2, 5'd1, 5'd0};

  // Compute core template: rv32imafd + SSR/frep/copift + FP extensions
  localparam core_cfg_t ComputeCoreCfg = '{
    RVE:                  0,
    RVF:                  1,
    RVD:                  1,
    XDivSqrt:             0,
    XF16:                 1,
    XF16ALT:              1,
    XF8:                  1,
    XF8ALT:               1,
    XFVEC:                1,
    XFDOTP:               1,
    Xdma:                 0,
    Xssr:                 1,
    Xfrep:                1,
    Xcopift:              1,
    Xpulppostmod:         0,
    Xpulpabs:             0,
    Xpulpbitop:           0,
    Xpulpbr:              0,
    Xpulpclip:            0,
    Xpulpmacsi:           0,
    Xpulpminmax:          0,
    Xpulpslet:            0,
    Xpulpvect:            0,
    Xpulpvectshufflepack: 0,
    PrivateIpu:           0,
    NumIntOutstandingLoads: 4,
    NumIntOutstandingMem:   4,
    NumFPOutstandingLoads:  4,
    NumFPOutstandingMem:    4,
    NumDTLBEntries:       1,
    NumITLBEntries:       1,
    NumSequencerInstr:    32,
    NumSequencerLoops:    2,
    NumSsrs:              3,
    SsrMuxRespDepth:      3,
    Hive:                 0,
    SsrCfgs: '{0: ComputeSsr0, 1: ComputeSsr1, 2: ComputeSsr2, default: '0},
    SsrRegs: ComputeSsrRegs
  };

  // DMA core template: rv32imafd + DMA, no SSR/FP extensions
  localparam core_cfg_t DmaCoreCfg = '{
    RVE:                  0,
    RVF:                  1,
    RVD:                  1,
    XDivSqrt:             0,
    XF16:                 0,
    XF16ALT:              0,
    XF8:                  0,
    XF8ALT:               0,
    XFVEC:                0,
    XFDOTP:               0,
    Xdma:                 1,
    Xssr:                 0,
    Xfrep:                0,
    Xcopift:              0,
    Xpulppostmod:         0,
    Xpulpabs:             0,
    Xpulpbitop:           0,
    Xpulpbr:              0,
    Xpulpclip:            0,
    Xpulpmacsi:           0,
    Xpulpminmax:          0,
    Xpulpslet:            0,
    Xpulpvect:            0,
    Xpulpvectshufflepack: 0,
    PrivateIpu:           0,
    NumIntOutstandingLoads: 4,
    NumIntOutstandingMem:   4,
    NumFPOutstandingLoads:  4,
    NumFPOutstandingMem:    4,
    NumDTLBEntries:       1,
    NumITLBEntries:       1,
    NumSequencerInstr:    16,
    NumSequencerLoops:    1,
    NumSsrs:              0,
    SsrMuxRespDepth:      3,
    Hive:                 0,
    SsrCfgs: '{default: '0},
    SsrRegs: '0
  };

  // Default cluster configuration (matches cfg/default.json)
  localparam snitch_cluster_cfg_t DefaultCfg = '{
    // Cluster identity
    ClusterBaseAddr:    64'h1000_0000,
    ClusterBaseOffset:  64'h0,
    BaseHartId:         0,

    // Widths
    AddrWidth:          48,
    NarrowDataWidth:    64,
    WideDataWidth:      512,

    // AXI IDs
    NarrowIdWidthIn:    2,
    WideIdWidthIn:      1,

    // Atomics / collectives
    AtomicIdWidth:      5,
    CollectiveWidth:    6,

    // Core & hive counts
    NrCores:            9,
    NrHives:            1,

    // TCDM
    Tcdm: '{
      Size:             128,
      Banks:            32,
      HyperBanks:       1,
      Topology:         snitch_pkg::LogarithmicInterconnect,
      Radix:            2,
      NumSwitchNets:    4,
      SwitchLfsrArbiter: 0
    },

    // Memory sizes
    ClusterPeriphSize:  60,
    ZeroMemorySize:     64,
    ExtMemorySize:      1,
    BootRomSize:        4,

    // DMA
    DmaNumAxInFlight:   24,
    DmaReqFifoDepth:    8,
    DmaNumChannels:     4,
    NumExpWideTcdmPorts: 0,

    // Outstanding transactions
    NarrowTrans:        4,
    WideTrans:          32,

    // Feature flags
    VMSupport:          0,
    EnableDebug:        0,
    EnableXif:          0,
    EnableDca:          0,
    EnableNarrowCollectives: 0,
    EnableWideCollectives:   0,
    AliasRegionEnable:  1,
    IntBootromEnable:   1,
    SramCfgExpose:      1,
    ClusterBaseExpose:  0,
    EnableExternalInterrupts: 0,
    NarrowAxiPortExpose: 0,

    // XIF
    XifIdWidth:         4,
    XifMisa:            0,

    // Boot & alias
    BootAddr:           32'h8000_0000,
    AliasRegionBase:    64'h1800_0000,

    // CAQ
    CaqDepth:           8,
    CaqTagWidth:        16,

    // DCA
    DcaDataWidth:       512,

    // FPU timing
    FpuTiming: '{
      LatCompFp32:    2,
      LatCompFp64:    3,
      LatCompFp16:    1,
      LatCompFp16Alt: 1,
      LatCompFp8:     1,
      LatCompFp8Alt:  1,
      LatNoncomp:     1,
      LatConv:        2,
      LatSdotp:       3,
      PipeConfig:     fpnew_pkg::BEFORE
    },

    // Timing
    Timing: '{
      RegisterOffloadReq: 1,
      RegisterOffloadRsp: 1,
      RegisterCoreReq:    1,
      RegisterCoreRsp:    1,
      RegisterTCDMCuts:   0,
      RegisterExtWide:    0,
      RegisterExtNarrow:  0,
      RegisterExpNarrow:  0,
      RegisterFPUReq:     1,
      RegisterFPUIn:      0,
      RegisterFPUOut:     0,
      RegisterDcaReq:     0,
      RegisterDcaRsp:     0,
      RegisterSequencer:  0,
      IsoCrossing:        0,
      NarrowXbarLatency:  axi_pkg::CUT_ALL_PORTS,
      WideXbarLatency:    axi_pkg::CUT_ALL_PORTS
    },

    // Hives (1 hive, rest zero)
    Hives: '{
      0: '{LineWidth: 512, LineCount: 128, Ways: 2, L1TagScm: 0, L1DataScm: 0},
      default: '0
    },

    // Cores (8 compute + 1 DMA, rest zero)
    Cores: '{
      0: ComputeCoreCfg,
      1: ComputeCoreCfg,
      2: ComputeCoreCfg,
      3: ComputeCoreCfg,
      4: ComputeCoreCfg,
      5: ComputeCoreCfg,
      6: ComputeCoreCfg,
      7: ComputeCoreCfg,
      8: DmaCoreCfg,
      default: '0
    },

    // PMA cached regions
    NrCachedRegions: 1,
    CachedRegions: '{
      0: '{Base: 64'h0000_8000_0000, Mask: 64'hFFFF_8000_0000},
      default: '0
    }
  };

endpackage
