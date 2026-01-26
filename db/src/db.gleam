import gleam/http
import cors_builder as cors
import gleam/erlang/process
import mist
import wisp/wisp_mist
import wisp.{type Request, type Response}
import sqlight.{type Connection}
import session
import sensor_event

fn handle_request(request: Request, connection: Connection) -> Response {
  use <- wisp.log_request(request)
  use <- wisp.rescue_crashes
  use request <- wisp.handle_head(request)
  use request <- cors.wisp_middleware(request, cors_config())

  case wisp.path_segments(request) {
    ["sessions"] -> session.handle_sessions(request, connection)
    ["events"] -> sensor_event.handle_events(request, connection)
    _ -> wisp.not_found()
  }
}

fn cors_config() {
  cors.new()
  |> cors.allow_origin("http://localhost:1234")
  |> cors.allow_origin("http://localhost:8000")
  |> cors.allow_method(http.Get)
  |> cors.allow_method(http.Post)
  |> cors.allow_header("Content-Type")
}

pub fn main() {
  wisp.configure_logger()
  let secret_key = "Skibidi67TungTungSahur"

  use connection <- sqlight.with_connection("database.db")
  let _ = sqlight.exec("
    CREATE TABLE IF NOT EXISTS sessions (
      uuid INTEGER PRIMARY KEY AUTOINCREMENT,
      started TEXT NOT NULL,
      ended TEXT NOT NULL,
      entered INTEGER NOT NULL,
      exited INTEGER NOT NULL
    );

    CREATE TABLE IF NOT EXISTS events (
      uuid INTEGER PRIMARY KEY AUTOINCREMENT,
      kind TEXT NOT NULL,
      time TEXT NOT NULL
    )
  ", connection)

  let assert Ok(_) =
    wisp_mist.handler(fn(request) { handle_request(request, connection) }, secret_key)
    |> mist.new
    |> mist.port(8000)
    |> mist.start

  process.sleep_forever()
}
