import gleam/list
import gleam/time/timestamp
import websocket
import gleam/int
import lustre
import lustre/effect.{type Effect}
import lustre/element/html.{div, h1, h2, p, text, table, th, tr, td, button}
import lustre/attribute.{class, styles, rel, href}
import lustre/event
import lustre/element.{type Element}
import gleam/option.{Some, None}
import model.{type Model, type Msg, ArchiveSession}

@external(javascript, "./localTime.mjs", "toLocalTime")
fn to_local_time(rfc3339: String) -> String

fn init(_) -> #(Model, Effect(Msg)) {
  websocket.connect_esp32()
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  websocket.sync_esp32(model, msg)
}

fn view(model: Model) -> Element(Msg) {
  div([class("main")], [
    div([class("titlebar-view")], [
      h1([], [text("People Counter")])
    ]),

    div([class("dashboard-view")], [
      case model.socket {
        Some(_) -> p([], [text("Board status: Connected")])
        None -> p([], [text("Board status: Disconnected")])
      },
      case model.stat {
        Some(t) -> div([], [
          p([], [text("Entered:")]),
          p([], [text(int.to_string(t.entered))]),
          p([], [text("Exited:")]),
          p([], [text(int.to_string(t.exited))]),
        ])
        None -> text("Waiting for data...")
      },
      button([class("archive-button"), event.on_click(ArchiveSession(timestamp.system_time()))], [text("Archive Session")])
    ]),

    div([class("events-view")], [
      h2([], [text("Events")]),
      case model.events {
        [] -> p([], [text("There's nothing here yet!")])
        events -> div([class("table")], [table([], [
          tr([], [
            th([], [text("ID")]),
            th([], [text("Time")]),
            th([], [text("Type")])
          ]),
          .. list.map(events, fn(event) {
            tr([], [
              td([], [text(int.to_string(event.uuid))]),
              td([], [text(to_local_time(event.time))]),
              td([], [text(event.kind)])
            ])
          })
        ])])
      }
    ]),

    div([class("sessions-view")], [
      h2([], [text("Sessions")]),
      case model.sessions {
        [] -> p([], [text("There's nothing here yet!")])
        sessions -> div([class("table")], [table([], [
          tr([], [
            th([], [text("ID")]),
            th([], [text("Started")]),
            th([], [text("Ended")]),
            th([], [text("Entered")]),
           th([], [text("Exited")]),
          ]),
          .. list.map(sessions, fn(session) {
            tr([], [
              td([], [text(int.to_string(session.uuid))]),
              td([], [text(to_local_time(session.started))]),
              td([], [text(to_local_time(session.ended))]),
              td([], [text(int.to_string(session.entered))]),
              td([], [text(int.to_string(session.exited))])
            ])
          })
        ])])
      }
    ])
  ])
}

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}
