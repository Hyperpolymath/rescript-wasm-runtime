# Contributing to ReScript WASM Runtime

Thank you for your interest in contributing! This guide will help you get started.

## 🎯 Ways to Contribute

- 🐛 Report bugs
- 💡 Propose new features
- 📝 Improve documentation
- 🔧 Submit bug fixes
- ✨ Implement new features
- 🧪 Add tests
- 📊 Improve benchmarks

## 🚀 Getting Started

### Prerequisites

- Node.js 16+ (for ReScript compiler)
- Deno 1.40+
- Just (task runner)
- Git
- Basic knowledge of ReScript and functional programming

### Setup

1. **Fork the repository**

```bash
# Click the "Fork" button on GitHub
```

2. **Clone your fork**

```bash
git clone https://github.com/YOUR_USERNAME/rescript-wasm-runtime.git
cd rescript-wasm-runtime
```

3. **Install dependencies**

```bash
npm install
```

4. **Build the project**

```bash
just build
```

5. **Run tests**

```bash
just test
```

6. **Create a feature branch**

```bash
git checkout -b feature/your-feature-name
```

## 📁 Project Structure

```
rescript-wasm-runtime/
├── src/                    # Core ReScript source files
│   ├── Deno.res           # Deno runtime bindings
│   ├── Server.res         # HTTP server implementation
│   ├── Router.res         # Routing with middleware
│   └── Middleware.res     # Common middleware
├── examples/              # Example applications
│   ├── hello-world/       # Minimal example
│   ├── api-server/        # RESTful API
│   ├── websocket/         # WebSocket server
│   └── ...
├── tests/                 # Test suite
│   ├── unit/             # Unit tests
│   └── integration/      # Integration tests
├── benchmark/            # Performance benchmarks
├── docs/                 # Documentation
├── scripts/              # Build and utility scripts
├── rescript.json         # ReScript configuration
├── justfile              # Build system tasks
└── package.json          # Node dependencies
```

## 🛠️ Development Workflow

### 1. Make Your Changes

#### Adding a New Feature

1. Write ReScript code in `src/`
2. Add tests in `tests/`
3. Update documentation
4. Add example if applicable

#### Example: Adding New Middleware

```rescript
// src/Middleware.res

// Add your middleware function
let myMiddleware = (~option: string): Router.middleware => {
  (req, next) => {
    // Your middleware logic
    Deno.log(`Custom middleware: ${option}`)
    next()
  }
}
```

### 2. Write Tests

```typescript
// tests/unit/middleware_test.ts

Deno.test("Middleware - My new middleware", async () => {
  // Test your middleware
  assertEquals(true, true);
});
```

### 3. Build and Test

```bash
# Build
just build

# Run tests
just test

# Run specific test
deno test tests/unit/middleware_test.ts

# Format code
just fmt

# Run linter
just lint
```

### 4. Commit Your Changes

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```bash
# Features
git commit -m "feat: add custom authentication middleware"

# Bug fixes
git commit -m "fix: resolve router path matching issue"

# Documentation
git commit -m "docs: update API reference for middleware"

# Tests
git commit -m "test: add integration tests for WebSocket"

# Performance
git commit -m "perf: optimize JSON parsing"

# Refactoring
git commit -m "refactor: simplify router middleware chain"
```

### 5. Push and Create PR

```bash
# Push to your fork
git push origin feature/your-feature-name

# Create Pull Request on GitHub
```

## ✅ Code Standards

### ReScript Style Guide

1. **Use type-safe patterns**

```rescript
// ✅ Good
let result = switch someValue {
| Some(value) => value
| None => defaultValue
}

// ❌ Avoid unsafe operations
let result = someValue->Option.getUnsafe
```

2. **Prefer immutability**

```rescript
// ✅ Good
let newArray = Array.concat(existingArray, [newItem])

// ❌ Avoid mutation when possible
Array.push(existingArray, newItem)
```

3. **Use descriptive names**

```rescript
// ✅ Good
let handleUserAuthentication = (credentials) => { ... }

// ❌ Avoid abbreviations
let handleAuth = (creds) => { ... }
```

4. **Document public APIs**

```rescript
// ✅ Good
// Create a new router instance with empty routes
// Returns: Router.t with no routes or middleware
let make = (): t => { ... }
```

### TypeScript/Deno Style (for tests)

1. Use TypeScript types
2. Follow Deno conventions
3. Use async/await over promises
4. Import from `https://deno.land/std/`

### Performance Considerations

1. **Bundle size**: Keep imports minimal
2. **Startup time**: Avoid heavy initialization
3. **Memory**: Prefer streaming over buffering
4. **Type safety**: Never sacrifice for performance

## 🧪 Testing Guidelines

### Unit Tests

Test individual functions and modules:

```typescript
Deno.test("Router - path matching with params", () => {
  // Test implementation
});
```

### Integration Tests

Test full request/response cycles:

```typescript
Deno.test("HTTP Server - POST request handling", async () => {
  const response = await fetch("http://localhost:8000/api", {
    method: "POST",
    body: JSON.stringify({ data: "test" }),
  });

  assertEquals(response.status, 200);
});
```

### Benchmark Tests

Compare performance:

```typescript
Deno.bench("Router - path matching", () => {
  // Benchmark code
});
```

### Coverage

Aim for >80% test coverage:

```bash
just test-coverage
```

## 📊 Benchmarking

When adding performance-critical features:

1. Add benchmarks in `benchmark/`
2. Compare before and after
3. Document improvements in PR

```bash
just bench
just bench-compare
```

## 📝 Documentation

### Code Documentation

- Add JSDoc-style comments for public APIs
- Include examples in documentation
- Document edge cases and limitations

### README Updates

Update README.md if:
- Adding new features
- Changing API
- Adding examples
- Updating benchmarks

### API Reference

Update `docs/api-reference.md` for API changes.

## 🔍 Code Review Process

Your PR will be reviewed for:

1. **Functionality**: Does it work as intended?
2. **Tests**: Are there adequate tests?
3. **Performance**: Does it maintain performance standards?
4. **Documentation**: Is it well documented?
5. **Style**: Does it follow the style guide?
6. **Breaking changes**: Are they necessary and documented?

### Review Timeline

- Initial review: 2-3 days
- Follow-up: 1-2 days
- Merge: After approval

## 🐛 Reporting Bugs

### Before Reporting

1. Check existing issues
2. Verify it's reproducible
3. Test on latest version

### Bug Report Template

```markdown
**Describe the bug**
A clear description of the bug.

**To Reproduce**
Steps to reproduce:
1. ...
2. ...

**Expected behavior**
What you expected to happen.

**Actual behavior**
What actually happened.

**Environment**
- OS: [e.g., macOS, Linux]
- Deno version: [e.g., 1.40.0]
- ReScript version: [e.g., 11.0.0]

**Additional context**
Any other relevant information.
```

## 💡 Feature Requests

### Before Requesting

1. Check existing feature requests
2. Consider if it fits project scope
3. Think about implementation

### Feature Request Template

```markdown
**Feature Description**
Clear description of the feature.

**Motivation**
Why is this feature needed?

**Proposed Solution**
How should it work?

**Alternatives Considered**
Other approaches you've thought about.

**Additional Context**
Any other relevant information.
```

## 🏆 Recognition

Contributors are recognized in:
- README.md contributors section
- Release notes
- GitHub contributors page

## 📜 License

By contributing, you agree that your contributions will be licensed under the MIT License.

## 🤝 Code of Conduct

### Our Pledge

We pledge to make participation in our project a harassment-free experience for everyone.

### Our Standards

**Positive behavior:**
- Using welcoming and inclusive language
- Being respectful of differing viewpoints
- Gracefully accepting constructive criticism
- Focusing on what is best for the community

**Unacceptable behavior:**
- Trolling, insulting/derogatory comments
- Public or private harassment
- Publishing others' private information
- Other unethical or unprofessional conduct

### Enforcement

Report violations to: conduct@example.com

## 📞 Getting Help

- 💬 Discord: [Join our server](https://discord.gg/example)
- 📧 Email: dev@example.com
- 📖 Docs: [Documentation](https://docs.example.com)

## 🙏 Thank You!

Every contribution, no matter how small, is valued and appreciated. Thank you for helping make ReScript WASM Runtime better!

---

**Happy Contributing! 🎉**
