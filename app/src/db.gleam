import gleam/json
import lustre/effect.{type Effect}
import model.{type Msg, GotSessionGetResponse, GotSessionPostResponse, GotEventGetResponse, GotEventPostResponse}
import rsvp


const url: String = "http://127.0.0.1:8000"

pub fn fetch_sessions() -> Effect(Msg) {
  let handler = rsvp.expect_json(model.sessions_decoder(), GotSessionGetResponse)
  rsvp.get(url <> "/sessions", handler)
}

pub fn write_sessions(started: String, ended: String, entered: Int, exited: Int) -> Effect(Msg) {
  let body = json.object([
    #("started", json.string(started)),
    #("ended", json.string(ended)),
    #("entered", json.int(entered)),
    #("exited", json.int(exited)),
  ])

  let handler = rsvp.expect_ok_response(GotSessionPostResponse)
  rsvp.post(url <> "/sessions", body, handler)
}


pub fn fetch_events() -> Effect(Msg) {
  let handler = rsvp.expect_json(model.events_decoder(), GotEventGetResponse)
  rsvp.get(url <> "/events", handler)
}

pub fn write_events(kind: String, time: String) -> Effect(Msg) {
  let body = json.object([
    #("kind", json.string(kind)),
    #("time", json.string(time))
  ])

  let handler = rsvp.expect_ok_response(GotEventPostResponse)
  rsvp.post(url <> "/events", body, handler)
}
