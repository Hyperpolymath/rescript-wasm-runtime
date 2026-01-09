// WebAssembly compilation and runtime support
// This module provides helpers for WASM compilation targets

// WASM memory management
module Memory = {
  type t

  @new external create: {"initial": int, "maximum": int} => t = "WebAssembly.Memory"
  @get external buffer: t => Js.Typed_array.ArrayBuffer.t = "buffer"
  @send external grow: (t, int) => int = "grow"

  // Get a Uint8Array view of memory
  let asUint8Array = (memory: t): Js.Typed_array.Uint8Array.t => {
    Js.Typed_array.Uint8Array.fromBuffer(buffer(memory))
  }

  // Copy bytes from ReScript to WASM memory at given offset
  let copyToWasm = (memory: t, offset: int, data: Js.Typed_array.Uint8Array.t): unit => {
    let view = asUint8Array(memory)
    let len = Js.Typed_array.Uint8Array.length(data)
    for i in 0 to len - 1 {
      let byte = Js.Typed_array.Uint8Array.unsafe_get(data, i)
      Js.Typed_array.Uint8Array.unsafe_set(view, offset + i, byte)
    }
  }

  // Copy bytes from WASM memory to ReScript
  let copyFromWasm = (memory: t, offset: int, len: int): Js.Typed_array.Uint8Array.t => {
    let view = asUint8Array(memory)
    Js.Typed_array.Uint8Array.subarray(view, ~start=offset, ~end_=offset + len)
  }

  // Write a 32-bit integer to memory (little-endian)
  let writeInt32 = (memory: t, offset: int, value: int): unit => {
    let view = asUint8Array(memory)
    Js.Typed_array.Uint8Array.unsafe_set(view, offset, land(value, 0xff))
    Js.Typed_array.Uint8Array.unsafe_set(view, offset + 1, land(lsr(value, 8), 0xff))
    Js.Typed_array.Uint8Array.unsafe_set(view, offset + 2, land(lsr(value, 16), 0xff))
    Js.Typed_array.Uint8Array.unsafe_set(view, offset + 3, land(lsr(value, 24), 0xff))
  }

  // Read a 32-bit integer from memory (little-endian)
  let readInt32 = (memory: t, offset: int): int => {
    let view = asUint8Array(memory)
    let b0 = Js.Typed_array.Uint8Array.unsafe_get(view, offset)
    let b1 = Js.Typed_array.Uint8Array.unsafe_get(view, offset + 1)
    let b2 = Js.Typed_array.Uint8Array.unsafe_get(view, offset + 2)
    let b3 = Js.Typed_array.Uint8Array.unsafe_get(view, offset + 3)
    lor(lor(lor(b0, lsl(b1, 8)), lsl(b2, 16)), lsl(b3, 24))
  }
}

// WASM allocator protocol - expected exports from WASM modules
module Allocator = {
  // Type for WASM pointer (offset into linear memory)
  type ptr = int

  // Null pointer constant
  let nullptr: ptr = 0

  // Check if pointer is valid
  let isValid = (p: ptr): bool => p > 0

  // Expected function signatures from WASM module exports
  type allocFn = int => ptr           // alloc(size) -> ptr
  type freeFn = ptr => unit           // free(ptr)
  type reallocFn = (ptr, int) => ptr  // realloc(ptr, new_size) -> ptr

  // Allocator instance wrapping WASM exports
  type t = {
    alloc: allocFn,
    free: freeFn,
    realloc: option<reallocFn>,
  }

  // Create allocator from WASM instance exports
  let fromExports = (exports: Instance.exports): t => {
    let allocFn: allocFn = %raw(`exports.alloc`)
    let freeFn: freeFn = %raw(`exports.free`)
    let reallocFn: option<reallocFn> = %raw(`exports.realloc ? exports.realloc : undefined`)
    {alloc: allocFn, free: freeFn, realloc: reallocFn}
  }

  // Allocate and copy data to WASM memory, returns pointer
  let allocBytes = (allocator: t, memory: Memory.t, data: Js.Typed_array.Uint8Array.t): ptr => {
    let len = Js.Typed_array.Uint8Array.length(data)
    let ptr = allocator.alloc(len)
    if isValid(ptr) {
      Memory.copyToWasm(memory, ptr, data)
    }
    ptr
  }

  // Read bytes from pointer and free the memory
  let readAndFree = (allocator: t, memory: Memory.t, ptr: ptr, len: int): Js.Typed_array.Uint8Array.t => {
    let data = Memory.copyFromWasm(memory, ptr, len)
    allocator.free(ptr)
    data
  }
}

// WASM table (for indirect function calls)
module Table = {
  type t

  @new external create: {"initial": int, "element": string} => t = "WebAssembly.Table"
  @send external get: (t, int) => 'a = "get"
  @send external set: (t, int, 'a) => unit = "set"
  @send external grow: (t, int) => int = "grow"
}

// WASM instance
module Instance = {
  type t
  type exports

  @get external exports: t => exports = "exports"
}

// WASM module
module Module = {
  type t

  @scope("WebAssembly") @val
  external compile: Js.Typed_array.ArrayBuffer.t => promise<t> = "compile"

  @scope("WebAssembly") @val
  external compileStreaming: 'response => promise<t> = "compileStreaming"

  @scope("WebAssembly") @val
  external validate: Js.Typed_array.ArrayBuffer.t => bool = "validate"

  @scope("WebAssembly") @val
  external instantiate: (t, 'imports) => promise<Instance.t> = "instantiate"

  @scope("WebAssembly") @val
  external instantiateStreaming: ('response, 'imports) => promise<{"module": t, "instance": Instance.t}> = "instantiateStreaming"
}

// Compilation configuration
type compileConfig = {
  optimize: bool,
  debug: bool,
  target: [#wasm32 | #wasm64],
  features: array<string>,
}

let defaultConfig: compileConfig = {
  optimize: true,
  debug: false,
  target: #wasm32,
  features: []
}

// Helper to load and instantiate WASM module
let loadModule = async (path: string, ~imports=?, ()): promise<Instance.t> => {
  try {
    let bytes = await Deno.Fs.readFile(path)
    let buffer = Js.Typed_array.Uint8Array.buffer(bytes)

    let module_ = await Module.compile(buffer)

    let importsObj = switch imports {
    | Some(i) => i
    | None => Js.Obj.empty()
    }

    await Module.instantiate(module_, importsObj)
  } catch {
  | error => {
      Deno.error("Failed to load WASM module")
      Deno.error(error)
      Js.Exn.raiseError("WASM module loading failed")
    }
  }
}

// Deno.Command bindings for subprocess execution
@new external makeCommand: (string, {"args": array<string>}) => 'command = "Deno.Command"
@send external output: 'command => promise<{"code": int, "stdout": Js.Typed_array.Uint8Array.t, "stderr": Js.Typed_array.Uint8Array.t}> = "output"

// TextDecoder binding
@new external makeTextDecoder: unit => 'decoder = "TextDecoder"
@send external decode: ('decoder, Js.Typed_array.Uint8Array.t) => string = "decode"

// Compile ReScript/WAT/Rust source to WASM
// Supports multiple input formats and uses appropriate toolchain
let compileToWasm = async (sourcePath: string, outputPath: string, ~config=defaultConfig, ()): promise<bool> => {
  let decoder = makeTextDecoder()

  // Determine source type from extension
  let ext = {
    let parts = sourcePath->Js.String2.split(".")
    parts->Array.get(Array.length(parts) - 1)->Option.getOr("")
  }

  Deno.log(`Compiling ${sourcePath} to WASM...`)
  Deno.log(`Source type: ${ext}`)
  Deno.log(`Target: ${config.target == #wasm32 ? "wasm32" : "wasm64"}`)
  Deno.log(`Optimize: ${config.optimize->Bool.toString}`)

  try {
    // Select toolchain based on source type
    let (cmd, args) = switch ext {
    | "wat" =>
      // WebAssembly Text format - use wat2wasm from WABT
      ("wat2wasm", [sourcePath, "-o", outputPath])
    | "rs" =>
      // Rust source - use cargo/rustc with wasm target
      let targetArg = config.target == #wasm32 ? "wasm32-unknown-unknown" : "wasm64-unknown-unknown"
      let releaseArg = config.optimize ? ["--release"] : []
      ("rustc", Array.concat(["--target", targetArg, "--crate-type", "cdylib", "-o", outputPath, sourcePath], releaseArg))
    | "c" | "cpp" =>
      // C/C++ - use emcc (Emscripten)
      let optimizeArg = config.optimize ? ["-O3"] : ["-O0"]
      ("emcc", Array.concat([sourcePath, "-o", outputPath, "-s", "WASM=1"], optimizeArg))
    | _ =>
      // Default: try AssemblyScript or fail gracefully
      ("asc", [sourcePath, "-o", outputPath, "--optimize"])
    }

    Deno.log(`Running: ${cmd} ${args->Array.join(" ")}`)

    let command = makeCommand(cmd, {"args": args})
    let result = await output(command)

    if result["code"] == 0 {
      Deno.log(`✓ Compiled successfully to ${outputPath}`)

      // Optional: run wasm-opt for additional optimization
      if config.optimize && ext != "wat" {
        Deno.log("Running wasm-opt for additional optimization...")
        let optCommand = makeCommand("wasm-opt", {
          "args": ["-O3", outputPath, "-o", outputPath]
        })
        let optResult = await output(optCommand)
        if optResult["code"] == 0 {
          Deno.log("✓ Optimization complete")
        } else {
          Deno.warn("wasm-opt not available, skipping optimization")
        }
      }

      true
    } else {
      let stderr = decode(decoder, result["stderr"])
      Deno.error(`Compilation failed with code ${Int.toString(result["code"])}`)
      Deno.error(stderr)
      false
    }
  } catch {
  | error => {
      Deno.error("Compilation error:")
      Deno.error(error)
      Deno.error("Ensure required tools are installed:")
      Deno.error("  - wat2wasm: npm install -g wabt")
      Deno.error("  - rustc: rustup target add wasm32-unknown-unknown")
      Deno.error("  - emcc: https://emscripten.org/docs/getting_started/downloads.html")
      Deno.error("  - asc: npm install -g assemblyscript")
      false
    }
  }
}

// WASM runtime environment setup
let setupRuntime = (): Js.Dict.t<'a> => {
  let env = Js.Dict.empty()

  // Memory management
  let memory = Memory.create({
    "initial": 256,  // 256 pages = 16MB
    "maximum": 16384 // 16384 pages = 1GB
  })

  Js.Dict.set(env, "memory", memory)

  // Import functions that WASM can call
  let imports = Js.Dict.empty()

  // Console functions
  Js.Dict.set(imports, "log", (msg: string) => Deno.log(msg))
  Js.Dict.set(imports, "error", (msg: string) => Deno.error(msg))

  // Math functions
  Js.Dict.set(imports, "random", () => Js.Math.random())

  // Date functions
  Js.Dict.set(imports, "now", () => Deno.now())

  Js.Dict.set(env, "imports", imports)

  env
}
