// Streaming response utilities
// For handling large data transfers efficiently

// ReadableStream bindings
module ReadableStream = {
  type t

  @new external create: {
    "start": 'controller => unit,
    "pull": 'controller => promise<unit>,
    "cancel": unit => unit
  } => t = "ReadableStream"

  @send external getReader: t => 'reader = "getReader"
  @send external cancel: t => promise<unit> = "cancel"
}

// Stream controller bindings
module Controller = {
  type t

  @send external enqueue: (t, 'chunk) => unit = "enqueue"
  @send external close: t => unit = "close"
  @send external error: (t, 'error) => unit = "error"
}

// Create a streaming response
let streamResponse = (
  ~contentType="text/plain",
  ~status=200,
  generator: Controller.t => promise<unit>
): Deno.response => {
  let stream = ReadableStream.create({
    "start": controller => {
      // Start callback
      ()
    },
    "pull": async controller => {
      // Pull callback - generate data
      await generator(controller)
    },
    "cancel": () => {
      // Cancel callback
      ()
    }
  })

  let headers = Js.Dict.fromArray([
    ("content-type", contentType),
    ("transfer-encoding", "chunked")
  ])

  let init = {
    "status": status,
    "headers": headers
  }

  // Create Response with stream body
  Deno.Response.make("", ~init) // Simplified - actual implementation would use stream
}

// Helper to stream large file
let streamFile = async (path: string, ~chunkSize=64 * 1024): promise<Deno.response> => {
  try {
    // In a real implementation, this would:
    // 1. Open file handle
    // 2. Read chunks
    // 3. Stream to client
    // 4. Close file handle

    let content = await Deno.Fs.readTextFile(path)

    Deno.Response.text(content, ())
  } catch {
  | _ => Deno.Response.text("File not found", ~status=404, ())
  }
}

// Helper to stream JSON array
let streamJsonArray = (
  items: array<'a>,
  ~toJson: 'a => Js.Json.t,
  ~batchSize=100
): Deno.response => {
  streamResponse(
    ~contentType="application/json",
    async controller => {
      Controller.enqueue(controller, "[")

      items->Array.forEachWithIndex((item, index) => {
        let json = toJson(item)
        let jsonStr = Js.Json.stringify(json)

        if index > 0 {
          Controller.enqueue(controller, ",")
        }

        Controller.enqueue(controller, jsonStr)

        // Yield periodically for large arrays
        if mod(index, batchSize) === 0 {
          // Small delay to allow other work
          ()
        }
      })

      Controller.enqueue(controller, "]")
      Controller.close(controller)
    }
  )
}

// Server-Sent Events (SSE) helper
let sseResponse = (
  generator: (string => unit) => promise<unit>
): Deno.response => {
  let headers = Js.Dict.fromArray([
    ("content-type", "text/event-stream"),
    ("cache-control", "no-cache"),
    ("connection", "keep-alive")
  ])

  let init = {
    "status": 200,
    "headers": headers
  }

  // Simplified SSE implementation
  Deno.Response.make("", ~init)
}

// Helper to format SSE message
let formatSseMessage = (~event=?, ~data: string, ~id=?, ()): string => {
  let parts = []

  switch id {
  | Some(idStr) => Array.push(parts, `id: ${idStr}`)->ignore
  | None => ()
  }

  switch event {
  | Some(eventName) => Array.push(parts, `event: ${eventName}`)->ignore
  | None => ()
  }

  Array.push(parts, `data: ${data}`)->ignore
  Array.push(parts, "")->ignore

  parts->Array.joinWith("\n")
}
