# openDAQ bindings for Ada

Ada 2022 bindings for [openDAQ](https://opendaq.com), the open-source
data-acquisition SDK, targeting openDAQ's official flat C API
(**copendaq**, `libcopendaq`).

```sh
./daq gen               # build the generator + regenerate both binding layers
./daq build             # alr build all crates
./daq run smoke_low     # raw C-level smoke test (instance + module listing)
./daq run quick_start   # high level: ref device -> typed stream reader
./daq check             # every gate: build + drift + symbol audit + examples
```

## Two layers, one generator

| Crate | Package | What | Source |
|---|---|---|---|
| `opendaq_bindings` | `Copendaq` | Thin 1:1 imports of the copendaq C ABI: ~1,700 subprograms, all opaque handle types, enums, error constants, interface ids. | generated from the **C headers** (`vendor/copendaq/include`) |
| `opendaq` | `Daq`, `Daq.API` | Thick idiomatic API: controlled (RAII, refcounted) wrappers, exceptions, `Obj.Method` notation, typed readers, event subscriptions. | hand-written core + `Daq.API` generated from headers + the **RTGen JSON model** (`model/`) |

The generator (`tools/opendaq_codegen`, its own Alire crate, pure Ada) parses
the machine-generated C headers directly for the ABI, and reads the RTGen
JSON model only for what headers cannot express: which interfaces exist and
their inheritance. Everything regenerates with `alr` alone — no mono, no
Dart. Generated code is committed (`*/src/gen/`); consumers never run the
generator.

### Low level (`Copendaq`)

- Hand-written prelude `copendaq.ads`: `daqErrCode`, `daqBool` (uint8),
  `daqIntfID` with `Convention => C_Pass_By_Copy` (it is passed **by value**
  to `queryInterface` — a plain C convention record would be passed by
  reference per RM B.3), callback access types, `daqCoreType`.
- Handles are typed addresses: `type daqSignal is new daqBaseObject;` — the
  Ada value *is* the C interface pointer; explicit conversions both ways.
- Function names keep the exact C spelling (`daqSignal_getPublic`) so all
  four language bindings stay grep-compatible. Out-params use `out` /
  `in out` modes (passed as `t*` per RM B.3).
- `Copendaq.Intf_IDs` quarantines the interface-id **data** imports (a
  Windows auto-import hazard); everything else uses the
  `daqX_getInterfaceId` functions.

### High level (`Daq` + generated `Daq.API`)

- `Daq.Object` is a controlled wrapper {handle, owned}: `Adjust` addRefs,
  `Finalize` releaseRefs — deterministic RAII. `Take` adopts a +1 ref,
  `Borrow` addRefs.
- Every generated operation takes `Self : T'Class` (prefix-callable, never a
  primitive) and **returns `T'Class`** for interface results — this dodges
  Ada's freezing/primitive rules for the 174 interconnected tagged types and
  keeps user code natural:

  ```ada
  Inst : constant Instance'Class := Daq.Boot.Create_Instance;
  Dev  : constant Device'Class :=
    Inst.Add_Device ("daqref://device0", Property_Object'(No_Object));
  for S of Dev.Get_Signals_Recursive (Search_Filter'(No_Object)) loop
     Put_Line (As_Signal (S).Get_Name);
  end loop;
  ```

- Typed nulls: every type inherits `No_Object` from `Daq.Object`, so
  `Search_Filter'(No_Object)` is the "pass NULL" idiom.
- Casts: generated `As_X` (queryInterface, raises `Cast_Error`) and `Is_X`
  (borrowInterface probe) per interface.
- Errors: `Check` raises `Opendaq_Error` when bit 31 of the `daqErrCode` is
  set; the message carries the symbolic `DAQ_ERR_*` name.
- Strings/lists/dicts: `String` in profiles, `Daq.Lists.List` (GNAT
  `Iterable`: `for X of L loop`), `Daq.Dicts.Dict`; boxed values via
  `As_Integer`/`As_Float`/`As_Boolean`/`As_String`/`To_Daq`.
- Events (`Daq.Events`): the C callbacks carry **no user-data pointer**, so
  `Subscribe` allocates one of 64 statically generated C trampolines bound
  to a protected slot table. Callbacks run on openDAQ's threads.
- Readers (`Daq.Stream_Readers`, generic; `Daq.Stream_Readers_F64`
  pre-instantiated): reads go straight into an Ada array — no per-sample
  marshalling. Raw-buffer C methods are deliberately not generated in
  `Daq.API` (the generator skips `void*` profiles); use the readers or the
  low-level imports.

## Toolchain (important on Apple Silicon)

Builds use **Alire**; `alr toolchain` must select an **aarch64** GNAT on
Apple Silicon. Beware an x86_64 `alr` binary (running under Rosetta): it detects
host-arch x86-64 and silently selects an x86_64 GNAT whose output cannot
link the arm64 `libcopendaq` — use a universal/arm64 `alr` (2.1.0+ releases
are universal). If an `alr` binary is dropped at `tools/bin/alr`, `./daq`
prefers it over the global one.

GNAT's gcc driver on macOS injects rpaths to its own toolchain dirs (one of
them twice, which newer dyld treats as a fatal duplicate `LC_RPATH`). The
GPRs pass `-nodefaultrpaths` on macOS to suppress that — the GNAT runtime
links statically, so those rpaths are never needed. Binaries therefore run
directly (`examples/bin/quick_start`) without any wrapper; the examples fall
back to the repo's `vendor/copendaq/lib` for module discovery when
`$OPENDAQ_MODULE_PATH` is unset.

## Vendor snapshot & regeneration

Committed inputs, all refreshed from **one** openDAQ build (mixing builds
causes header/library skew):

- `vendor/copendaq/include/` — the C headers (ABI ground truth) + `VERSION`
- `vendor/copendaq/symbols.txt` — `nm` export list of that build's
  `libcopendaq`; the high-level generator skips wrappers for
  header-declared-but-unexported functions (~120 in current builds) so
  executables never hit missing symbols
- `vendor/copendaq/lib` — gitignored symlink to the build's `bin/` (link +
  run path; point it at a build that ships the reference-device module so
  the examples can run)
- `model/` — RTGen JSON interface model (extracted from openDAQ's RTGen,
  refreshable via `scripts/refresh_model.sh`)

ABI bump procedure:

```sh
./daq refresh <opendaq-build-dir>   # headers + symbols + lib symlink + VERSION
scripts/refresh_model.sh --copy <model-dir>   # model JSON (when the model moved too)
./daq gen                           # regenerate; review the skip report
./daq check                         # gates: build, drift, symbols, examples
git add vendor model */src/gen && git commit
```

The generator is deterministic (sorted inputs, no timestamps,
write-if-changed); `opendaq_codegen check` exits 2 on any drift between
inputs and committed generated code.

## Platforms

- **macOS arm64** — built and verified here (both examples).
- **Linux x86_64** — link config in `opendaq_bindings.gpr` (`OPENDAQ_OS`
  scenario, rpath + `--enable-new-dtags`); needs a Linux openDAQ build to
  verify.
- **Windows x64** — MinGW direct-to-DLL link configured but unverified; if
  ld balks, drop an import lib next to `copendaq.dll`
  (`gendef copendaq.dll && dlltool -d copendaq.def -D copendaq.dll -l
  libcopendaq.dll.a`). Interface-id data imports are quarantined in
  `Copendaq.Intf_IDs`, so ordinary API use never needs auto-import.

Set `COPENDAQ_LIB_DIR` (env or GPR external) to point builds at a different
openDAQ; `COPENDAQ_CORETYPES_LIB` overrides the versioned coretypes library
name (`daqcoretypes-64-3`) that provides `daqFreeMemory`.

## Examples

Each example runs standalone (`examples/bin/<name>`) or via
`./daq run <name>`, and all run in `./daq check`:

| Example | Shows |
|---|---|
| `smoke_low` | raw C-level ABI validation (strings, queryInterface, refcounts, modules) |
| `quick_start` | connect ref device → typed stream reader |
| `add_function_block` | channel by path, Statistics FB, input-port wiring, **MultiReader** on avg+rms |
| `component_tree` | recursive component walk with kinds + visible properties |
| `call_function` | calling an IFunction property (`Protected.Sum`; skips without a simulator) |
| `core_events` | core-event subscription (trampoline pool) observing property changes |
| `signals_packets` | descriptor builders, programmatic signals, **packet writing**, read-back |
| `device_modes` | operation modes + device lock/unlock |

## Editor / LSP

The [Ada Language Server](https://github.com/AdaCore/ada_language_server)
works out of the box here: root an editor session at any crate directory (or
just open a source file — root on `alire.toml`) and ALS queries `alr` for
the project and cross-crate paths itself, so completion and go-to-definition
resolve across all four crates, including into `src/gen`. Install: unpack
the `darwin-arm64` release (binary + its bundled `libgmp.10.dylib` must stay
side by side) and put the binary on `PATH`. Neovim (0.11+ native LSP):

```lua
-- ~/.config/nvim/lsp/adalsp.lua
return {
  cmd = { 'ada_language_server' },
  filetypes = { 'ada' },
  root_markers = { 'alire.toml', '.git' },
}
-- init.lua: vim.lsp.enable('adalsp')
```

## Layout

```
daq                        task runner (gen | build | check | run | symbols | refresh | clean)
vendor/copendaq/           committed header snapshot, symbols.txt, VERSION; lib -> build bin/
model/                     committed RTGen JSON model (+ VERSION)
tools/opendaq_codegen/     the generator crate (self-hosted Ada)
opendaq_bindings/          crate 1: src/copendaq.ads (hand) + src/gen/ (generated)
opendaq/                   crate 2: src/daq*.ads|adb (hand core) + src/gen/daq-api.* (generated)
examples/                  see Examples below
scripts/                   env, refresh_vendor, refresh_model, check_symbols
```
