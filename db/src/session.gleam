import gleam/int
import gleam/json
import gleam/http
import gleam/result
import gleam/dynamic/decode
import sqlight.{type Connection}
import wisp.{type Request, type Response}

pub type Session {
  Session(
    uuid: Int,
    started: String,
    ended: String,
    entered: Int,
    exited: Int
  )
}

pub type CreatedSession {
  CreatedSession(
    started: String,
    ended: String,
    entered: Int,
    exited: Int
  )
}

fn session_decoder() {
  use uuid <- decode.field(0, decode.int)
  use started <- decode.field(1, decode.string)
  use ended <- decode.field(2, decode.string)
  use entered <- decode.field(3, decode.int)
  use exited <- decode.field(4, decode.int)
  decode.success(Session(uuid, started, ended, entered, exited))
}

fn created_session_decoder() {
  use started <- decode.field("started", decode.string)
  use ended <- decode.field("ended", decode.string)
  use entered <- decode.field("entered", decode.int)
  use exited <- decode.field("exited", decode.int)
  decode.success(CreatedSession(started, ended, entered, exited))
}


pub fn handle_sessions(request: Request, connection: Connection) -> Response {
  case request.method {
    http.Get -> {
      let assert Ok(sessions) = sqlight.query("SELECT * FROM sessions", on: connection, with: [], expecting: session_decoder())

      let body = json.array(sessions, fn(session: Session) {
        json.object([
          #("uuid", json.int(session.uuid)),
          #("started", json.string(session.started)),
          #("ended", json.string(session.ended)),
          #("entered", json.int(session.entered)),
          #("exited", json.int(session.exited)),
        ])
      })
      wisp.json_response(json.to_string(body), 200)
    }

    http.Post -> {
      let result = {
        use body <- result.try(wisp.read_body_bits(request))
        use session <- result.try(
          json.parse_bits(body, created_session_decoder())
          |> result.map_error(fn(_) { Nil })
        )

        let assert Ok(_) = sqlight.exec(
          "INSERT INTO sessions (started, ended, entered, exited) VALUES ("
          <> "'" <> session.started <> "', "
          <> "'" <> session.ended <> "', "
          <> int.to_string(session.entered) <> ", "
          <> int.to_string(session.exited)
          <> ")",
          connection,
        )
        Ok(wisp.created())
      }

      case result {
        Ok(response) -> response
        Error(_) -> wisp.bad_request("Invalid JSON")
      }
    }

    _ -> wisp.method_not_allowed([http.Get, http.Post])
  }
}
