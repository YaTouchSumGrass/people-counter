import gleam/json
import gleam/http
import gleam/result
import gleam/dynamic/decode
import sqlight.{type Connection}
import wisp.{type Request, type Response}

pub type SensorEvent {
  SensorEvent(
    uuid: Int,
    kind: String,
    time: String
  )
}

pub type CreatedSensorEvent {
  CreatedSensorEvent(
    kind: String,
    time: String
  )
}


fn event_decoder() {
  use uuid <- decode.field(0, decode.int)
  use kind <- decode.field(1, decode.string)
  use time <- decode.field(2, decode.string)
  decode.success(SensorEvent(uuid, kind, time))
}

fn created_event_decoder() {
  use kind <- decode.field("kind", decode.string)
  use time <- decode.field("time", decode.string)
  decode.success(CreatedSensorEvent(kind, time))
}


pub fn handle_events(request: Request, connection: Connection) -> Response {
  case request.method {
    http.Get -> {
      let assert Ok(events) = sqlight.query("SELECT * FROM events", on: connection, with: [], expecting: event_decoder())

      let body = json.array(events, fn(event: SensorEvent) {
        json.object([
          #("uuid", json.int(event.uuid)),
          #("kind", json.string(event.kind)),
          #("time", json.string(event.time)),
        ])
      })
      wisp.json_response(json.to_string(body), 200)
    }

    http.Post -> {
      let result = {
        use body <- result.try(wisp.read_body_bits(request))
        use event <- result.try(
          json.parse_bits(body, created_event_decoder())
          |> result.map_error(fn(_) { Nil })
        )

        let assert Ok(_) = sqlight.exec(
          "INSERT INTO events (kind, time) VALUES ("
          <> "'" <> event.kind <> "', "
          <> "'" <> event.time <> "'"
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
