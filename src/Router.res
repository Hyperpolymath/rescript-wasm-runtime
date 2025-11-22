// HTTP Router with type-safe routing and middleware support

type method = GET | POST | PUT | DELETE | PATCH | OPTIONS | HEAD
type route = {
  method: method,
  path: string,
  handler: Deno.request => promise<Deno.response>
}

type middleware = (Deno.request, unit => promise<Deno.response>) => promise<Deno.response>

type t = {
  routes: array<route>,
  middlewares: array<middleware>,
  notFoundHandler: option<Deno.request => promise<Deno.response>>
}

let make = (): t => {
  routes: [],
  middlewares: [],
  notFoundHandler: None
}

let methodToString = (method: method): string => {
  switch method {
  | GET => "GET"
  | POST => "POST"
  | PUT => "PUT"
  | DELETE => "DELETE"
  | PATCH => "PATCH"
  | OPTIONS => "OPTIONS"
  | HEAD => "HEAD"
  }
}

let methodFromString = (str: string): option<method> => {
  switch str {
  | "GET" => Some(GET)
  | "POST" => Some(POST)
  | "PUT" => Some(PUT)
  | "DELETE" => Some(DELETE)
  | "PATCH" => Some(PATCH)
  | "OPTIONS" => Some(OPTIONS)
  | "HEAD" => Some(HEAD)
  | _ => None
  }
}

// Path matching with named parameters
let matchPath = (pattern: string, path: string): option<Js.Dict.t<string>> => {
  let patternParts = pattern->Js.String2.split("/")->Array.keep(p => p !== "")
  let pathParts = path->Js.String2.split("/")->Array.keep(p => p !== "")

  if Array.length(patternParts) !== Array.length(pathParts) {
    None
  } else {
    let params = Js.Dict.empty()
    let matches = ref(true)

    Array.forEachWithIndex(patternParts, (patternPart, i) => {
      let pathPart = Array.getUnsafe(pathParts, i)

      if Js.String2.startsWith(patternPart, ":") {
        let paramName = Js.String2.sliceToEnd(patternPart, ~from=1)
        Js.Dict.set(params, paramName, pathPart)
      } else if patternPart !== pathPart {
        matches := false
      }
    })

    if matches.contents {
      Some(params)
    } else {
      None
    }
  }
}

// Add route
let addRoute = (router: t, method: method, path: string, handler: Deno.request => promise<Deno.response>): t => {
  let newRoute = {method, path, handler}
  {...router, routes: Array.concat(router.routes, [newRoute])}
}

// Route registration helpers
let get = (router: t, path: string, handler: Deno.request => promise<Deno.response>): t => {
  addRoute(router, GET, path, handler)
}

let post = (router: t, path: string, handler: Deno.request => promise<Deno.response>): t => {
  addRoute(router, POST, path, handler)
}

let put = (router: t, path: string, handler: Deno.request => promise<Deno.response>): t => {
  addRoute(router, PUT, path, handler)
}

let del = (router: t, path: string, handler: Deno.request => promise<Deno.response>): t => {
  addRoute(router, DELETE, path, handler)
}

let patch = (router: t, path: string, handler: Deno.request => promise<Deno.response>): t => {
  addRoute(router, PATCH, path, handler)
}

let options = (router: t, path: string, handler: Deno.request => promise<Deno.response>): t => {
  addRoute(router, OPTIONS, path, handler)
}

// Add middleware
let use = (router: t, middleware: middleware): t => {
  {...router, middlewares: Array.concat(router.middlewares, [middleware])}
}

// Set custom 404 handler
let notFound = (router: t, handler: Deno.request => promise<Deno.response>): t => {
  {...router, notFoundHandler: Some(handler)}
}

// Handle request
let handle = async (router: t, req: Deno.request): promise<Deno.response> => {
  let method = Deno.Request.method(req)
  let url = Deno.Request.url(req)
  let urlObj = Deno.Url.make(url)
  let path = Deno.Url.pathname(urlObj)

  let methodEnum = methodFromString(method)

  switch methodEnum {
  | None => Deno.Response.text("Method not allowed", ~status=405, ())
  | Some(m) => {
      // Find matching route
      let matchingRoute = ref(None)

      Array.forEach(router.routes, route => {
        if route.method === m {
          switch matchPath(route.path, path) {
          | Some(_params) => matchingRoute := Some(route)
          | None => ()
          }
        }
      })

      switch matchingRoute.contents {
      | None => {
          // No route found, use 404 handler
          switch router.notFoundHandler {
          | Some(handler) => await handler(req)
          | None => Deno.Response.text("Not Found", ~status=404, ())
          }
        }
      | Some(route) => {
          // Apply middlewares
          let finalHandler = () => route.handler(req)

          let wrappedHandler = Array.reduceReverse(router.middlewares, finalHandler, (next, middleware) => {
            () => middleware(req, next)
          })

          await wrappedHandler()
        }
      }
    }
  }
}
