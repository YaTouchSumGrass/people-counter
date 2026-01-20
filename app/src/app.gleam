import gleam/list
import gleam/time/timestamp
import websocket
import gleam/int
import lustre
import lustre/effect.{type Effect}
import lustre/element/html
import lustre/event
import lustre/attribute
import lustre/element.{type Element}
import gleam/option.{Some, None}
import model.{type Model, type Msg, ArchiveSession}

fn init(_) -> #(Model, Effect(Msg)) {
  websocket.connect_esp32()
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
<<<<<<< HEAD
  case msg {
    OnReceiveMessage(event) -> case event {
      ws.OnOpen(socket) -> #(Model(..model, socket: Some(socket)), effect.none())

      ws.OnTextMessage(text) -> {
        let decoder = {
          use entered <- decode.field("entered", decode.int)
          use exited <- decode.field("exited", decode.int)
          decode.success(Stat(entered, exited))
        }

        let stat = case json.parse(text, decoder) {
          Ok(t) -> Some(t)
          Error(_) -> None
        }

        #(Model(..model, stat: stat), effect.none())
      }

      ws.InvalidUrl -> {
        io.println("Invalid WebSocket URL!")
        #(model, effect.none())
      }

      _ -> #(model, effect.none())
    }
    Refresh -> #(model, ws.init("ws://192.168.4.1/ws", OnReceiveMessage))
  }
=======
  websocket.sync_esp32(model, msg)
>>>>>>> 3fb9c33 (feat: databases + sessions + archiving)
}

fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("main")], [
    html.h1([], [html.text("People Counter")]),
    case model.socket {
      Some(_) -> html.p([], [html.text("Board status: Connected")])
      None -> html.p([], [html.text("Board status: Disconnected")])
    },
    case model.stat {
      Some(t) -> html.div([], [
        html.p([], [html.text("Entered:")]),
        html.p([], [html.text(int.to_string(t.entered))]),
        html.p([], [html.text("Exited:")]),
        html.p([], [html.text(int.to_string(t.exited))]),
      ])
      None -> html.text("Waiting for data...")
    },
    html.button([event.on_click(ArchiveSession(timestamp.system_time()))], [html.text("Archive Session")]),

    html.div([attribute.class("db-view")], [
      html.h2([], [html.text("Sessions")]),
      case model.sessions {
        [] -> html.p([], [html.text("There's nothing here yet!")])
        sessions -> html.table([
            attribute.styles([#("border-spacing", "20px 5px")])
          ], [
          html.tr([], [
            html.th([], [html.text("ID")]),
            html.th([], [html.text("Started")]),
            html.th([], [html.text("Ended")]),
            html.th([], [html.text("Entered")]),
           html.th([], [html.text("Exited")]),
          ]),
          .. list.map(sessions, fn(session) {
            html.tr([], [
              html.td([], [html.text(int.to_string(session.uuid))]),
              html.td([], [html.text(session.started)]),
              html.td([], [html.text(session.ended)]),
              html.td([], [html.text(int.to_string(session.entered))]),
              html.td([], [html.text(int.to_string(session.exited))])
            ])
          })
        ])
      }
    ])
  ])
}

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}
