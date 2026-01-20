import gleam/http/response.{type Response}
import gleam/time/timestamp.{type Timestamp}
import lustre_websocket as ws
import gleam/option.{type Option, Some, None}
import gleam/dynamic/decode
import gleam/json
import rsvp

pub type Stat {
  Stat(
    boot_id: String,
    entered: Int,
    exited: Int,
  )
}

pub type Msg {
  OnReceiveMessage(ws.WebSocketEvent)
  GotGetResponse(Result(List(Session), rsvp.Error))
  GotPostResponse(Result(Response(String), rsvp.Error))
  ArchiveSession(Timestamp)
}

pub type Model {
  Model(
    started: Timestamp,
    stat: Option(Stat),
    socket: Option(ws.WebSocket),
    sessions: List(Session)
  )
}

pub type Session {
  Session(
    uuid: Int,
    started: String,
    ended: String,
    entered: Int,
    exited: Int
  )
}

pub fn sessions_decoder() {
  decode.list({
    use uuid <- decode.field("uuid", decode.int)
    use started <- decode.field("started", decode.string)
    use ended <- decode.field("ended", decode.string)
    use entered <- decode.field("entered", decode.int)
    use exited <- decode.field("exited", decode.int)
    decode.success(Session(uuid, started, ended, entered, exited))
  })
}

pub fn decode_stat(text: String) -> Option(Stat) {
  let decoder = {
    use boot_id <- decode.field("boot_id", decode.string)
    use entered <- decode.field("entered", decode.int)
    use exited <- decode.field("exited", decode.int)
    decode.success(Stat(boot_id, entered, exited))
  }

  case json.parse(text, decoder) {
    Ok(t) -> Some(t)
    Error(_) -> None
  }
}
