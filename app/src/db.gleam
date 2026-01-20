import gleam/json
import lustre/effect.{type Effect}
import model.{type Msg, GotGetResponse, GotPostResponse}
import rsvp


const url: String = "http://127.0.0.1:8000/sessions"

pub fn fetch_data() -> Effect(Msg) {
  let handler = rsvp.expect_json(model.sessions_decoder(), GotGetResponse)
  rsvp.get(url, handler)
}

pub fn write_data(started: String, ended: String, entered: Int, exited: Int) -> Effect(Msg) {
  let body = json.object([
    #("started", json.string(started)),
    #("ended", json.string(ended)),
    #("entered", json.int(entered)),
    #("exited", json.int(exited)),
  ])

  let handler = rsvp.expect_ok_response(GotPostResponse)
  rsvp.post(url, body, handler)
}
