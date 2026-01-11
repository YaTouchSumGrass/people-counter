import gleam/io
import gleam/int
import lustre
import lustre_websocket as ws
import lustre/effect.{type Effect}
import lustre/element/html
import lustre/attribute
import lustre/event
import lustre/element.{type Element}
import gleam/option.{type Option, Some, None}
import gleam/json
import gleam/dynamic/decode

type Stat {
  Stat(
    entered: Int,
    exited: Int
  )
}

type Msg {
  OnReceiveMessage(ws.WebSocketEvent)
  Refresh
}

type Model {
  Model(
    stat: Option(Stat),
    socket: Option(ws.WebSocket)
  )
}

fn init(_) -> #(Model, Effect(Msg)) {
  #(
    Model(stat: Some(Stat(entered: 0, exited: 0)), socket: None),
    ws.init("ws://192.168.4.1/ws", OnReceiveMessage)
  )
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
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
    Refresh -> #(model, ws.init("ws://172.22.45.54/ws", OnReceiveMessage))
  }
}

fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("main")], [
    html.h1([], [html.text("People Counter")]),
    case model.socket {
      Some(_) -> case model.stat {
        Some(t) -> html.div([], [
          html.p([], [html.text("Entered:")]),
          html.p([], [html.text(int.to_string(t.entered))]),
          html.p([], [html.text("Exited:")]),
          html.p([], [html.text(int.to_string(t.exited))]),
        ])
        None -> html.text("Error deserializing data.")
      }
      None -> html.text("Waiting for data...")
    },
    html.button([event.on_click(Refresh)], [html.text("Refresh")])
  ])
}

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}
