# ReScript WASM Runtime

## Project Overview

This project provides a WebAssembly (WASM) runtime for ReScript, enabling ReScript code to be compiled to and executed as WebAssembly modules. This bridges ReScript's type-safe functional programming with the performance and portability benefits of WebAssembly.

## Purpose

The rescript-wasm-runtime enables:
- Compilation of ReScript code to WebAssembly
- Runtime support for executing ReScript-generated WASM modules
- Interoperability between ReScript and WebAssembly environments
- High-performance execution of ReScript applications in WASM-capable environments

## Tech Stack

- **ReScript**: Type-safe functional programming language that compiles to JavaScript/WASM
- **WebAssembly**: Binary instruction format for stack-based virtual machines
- **JavaScript/TypeScript**: For runtime support and bindings
- **Node.js**: Build and development tooling

## Project Structure

```
/
├── src/              # Source code for the runtime
├── examples/         # Example ReScript programs compiled to WASM
├── tests/            # Test suite
├── lib/              # Compiled output
└── bindings/         # Language bindings and FFI interfaces
```

## Development

### Prerequisites

- Node.js (v16+)
- ReScript compiler
- WASM toolchain

### Building

```bash
npm install
npm run build
```

### Testing

```bash
npm test
```

## Architecture

The runtime consists of:

1. **Compiler Integration**: Hooks into the ReScript compiler to generate WASM output
2. **Runtime Library**: Support code for executing ReScript WASM modules
3. **Memory Management**: Garbage collection and memory allocation for WASM environment
4. **FFI Layer**: Foreign Function Interface for calling between ReScript and host environment
5. **Standard Library**: Core ReScript standard library compiled for WASM

## Key Concepts

### ReScript to WASM Compilation

ReScript code is compiled to WebAssembly through a multi-stage process:
1. ReScript source → ReScript AST
2. ReScript AST → Intermediate representation
3. IR → WASM bytecode
4. WASM bytecode → Optimized WASM module

### Runtime Support

The runtime provides:
- Memory allocators compatible with ReScript's memory model
- Garbage collection for WASM linear memory
- Exception handling bridging
- Module loading and initialization
- Standard library implementations

## Contributing

When working on this codebase:

1. **Type Safety**: Maintain strict type safety across ReScript and WASM boundaries
2. **Performance**: Consider WASM performance characteristics (linear memory, stack machine)
3. **Compatibility**: Ensure compatibility with ReScript language features
4. **Testing**: Add tests for new runtime features and compiler changes
5. **Documentation**: Document public APIs and runtime behavior

## Common Tasks

### Adding New Runtime Features

1. Define the feature in ReScript
2. Implement runtime support functions
3. Add compiler integration to generate appropriate WASM
4. Create tests demonstrating the feature
5. Update documentation

### Debugging WASM Output

- Use `wasm-objdump` to inspect generated WASM modules
- Use browser DevTools or Node.js debugging for runtime issues
- Add logging/tracing to the runtime for complex issues

## References

- [ReScript Documentation](https://rescript-lang.org/)
- [WebAssembly Specification](https://webassembly.github.io/spec/)
- [WASM Reference Manual](https://github.com/WebAssembly/design)

## License

[License information to be added]
