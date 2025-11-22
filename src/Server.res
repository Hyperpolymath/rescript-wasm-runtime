// HTTP Server implementation for Deno

type config = {
  port: int,
  hostname: string,
  onListen: option<Deno.addr => unit>
}

let defaultConfig = {
  port: 8000,
  hostname: "127.0.0.1",
  onListen: None
}

let make = (
  ~port=8000,
  ~hostname="127.0.0.1",
  ~onListen=?,
  handler: Deno.request => promise<Deno.response>
): unit => {
  let options = {
    "port": port,
    "hostname": hostname,
    "onListen": addr => {
      switch onListen {
      | Some(fn) => fn(addr)
      | None => Deno.log(`Server running on http://${addr.hostname}:${Int.toString(addr.port)}`)
      }
    }
  }

  let _ = Deno.serveWithOptions(handler, options)
}

// Convenience function for creating a server with a router
let withRouter = (
  ~port=8000,
  ~hostname="127.0.0.1",
  ~onListen=?,
  router: Router.t
): unit => {
  make(~port, ~hostname, ~onListen?, req => Router.handle(router, req))
}

// Create a simple server with a single handler
let simple = (
  ~port=8000,
  ~hostname="127.0.0.1",
  handler: Deno.request => promise<Deno.response>
): unit => {
  make(~port, ~hostname, handler)
}
