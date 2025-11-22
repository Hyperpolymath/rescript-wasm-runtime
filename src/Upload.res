// File upload handling utilities

// FormData types
type formDataEntry = {
  name: string,
  value: string,
  filename: option<string>,
  contentType: option<string>
}

// Parse multipart/form-data (simplified)
let parseFormData = async (req: Deno.request): promise<array<formDataEntry>> => {
  try {
    // In a real implementation, this would:
    // 1. Get boundary from Content-Type header
    // 2. Split body by boundary
    // 3. Parse each part
    // 4. Extract files and fields

    let _body = await Deno.Request.text(req)

    // Placeholder - return empty array
    []
  } catch {
  | _ => []
  }
}

// Save uploaded file
let saveFile = async (
  file: formDataEntry,
  ~directory="uploads",
  ~maxSize=10 * 1024 * 1024 // 10MB
): promise<result<string, string>> => {
  try {
    // Validate file
    if String.length(file.value) > maxSize {
      Promise.resolve(Error("File too large"))
    } else {
      switch file.filename {
      | None => Promise.resolve(Error("No filename provided"))
      | Some(filename) => {
          // Generate unique filename
          let timestamp = Deno.now()->Float.toString
          let uniqueFilename = `${timestamp}_${filename}`
          let filepath = `${directory}/${uniqueFilename}`

          // In production, this would save the actual file
          // await Deno.Fs.writeTextFile(filepath, file.value)

          Promise.resolve(Ok(filepath))
        }
      }
    }
  } catch {
  | error => {
      let message = error->Js.Exn.message->Option.getWithDefault("Unknown error")
      Promise.resolve(Error(message))
    }
  }
}

// Validate file type
let validateFileType = (
  filename: string,
  ~allowedExtensions: array<string>
): bool => {
  let lowerFilename = Js.String2.toLowerCase(filename)

  allowedExtensions->Array.some(ext => {
    Js.String2.endsWith(lowerFilename, Js.String2.toLowerCase(ext))
  })
}

// Generate safe filename
let sanitizeFilename = (filename: string): string => {
  filename
    ->Js.String2.replaceByRe(%re("/[^a-zA-Z0-9._-]/g"), "_")
    ->Js.String2.replaceByRe(%re("/\.{2,}/g"), ".")
}

// Upload middleware
let uploadMiddleware = (
  ~maxFileSize=10 * 1024 * 1024,
  ~allowedTypes=["jpg", "jpeg", "png", "gif", "pdf"]
): Router.middleware => {
  (req, next) => {
    let headers = Deno.Request.headers(req)
    let contentType = Js.Dict.get(headers, "content-type")

    switch contentType {
    | Some(ct) when Js.String2.includes(ct, "multipart/form-data") => {
        // Handle file upload
        parseFormData(req)->Promise.then(entries => {
          // Process entries
          Deno.log(`Received ${Int.toString(Array.length(entries))} form entries`)
          next()
        })
      }
    | _ => next()
    }
  }
}
