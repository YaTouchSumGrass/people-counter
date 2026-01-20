import gleam/time/calendar
import gleam/time/timestamp
import gleam/io
import model.{type Model, Model, type Msg, OnReceiveMessage, GotGetResponse, GotPostResponse, ArchiveSession}
import gleam/option.{Some, None}
import lustre/effect.{type Effect}
import lustre_websocket as ws
import db


pub fn connect_esp32() -> #(Model, Effect(Msg)) {
  #(
    Model(
      started: timestamp.from_unix_seconds(0),
      stat: None,
      socket: None,
      sessions: []
    ),
    ws.init("ws://192.168.4.1:80/ws", OnReceiveMessage)
  )
}

pub fn sync_esp32(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    OnReceiveMessage(event) -> {
      case event {
        ws.OnOpen(socket) -> {
          let started = timestamp.system_time()
          #(Model(..model, started: started, socket: Some(socket)), effect.none())
        }

        ws.OnTextMessage(text) -> {
          let stat = model.decode_stat(text)
          #(Model(..model, stat: stat), effect.none())
        }

        ws.InvalidUrl -> {
          io.println("Invalid WebSocket URL!")
          #(model, effect.none())
        }

        _ -> #(model, effect.none())
      }
    }

    GotGetResponse(result) -> {
      case result {
        Ok(sessions) -> #(
          Model(..model, sessions: sessions),
          effect.none()
        )
        Error(err) -> {
          echo err
          #(model, effect.none())
        }
      }
    }

    GotPostResponse(result) -> {
      case model.socket, result {
        Some(socket), Ok(response) -> {
          case response.status {
            201 -> {
              #(model, effect.batch([
                db.fetch_data(),
                ws.send(socket, "ARCHIVE")
              ]))
            }
            _ -> #(model, effect.none())
          }
        }
        _, Error(err) -> {
          echo err
          #(model, effect.none())
        }

        _, _ -> #(model, effect.none())
      }
    }

    ArchiveSession(ended) -> {
      case model.stat {
        Some(stat) -> {
          #(model, db.write_data(
            timestamp.to_rfc3339(model.started, calendar.utc_offset),
            timestamp.to_rfc3339(ended, calendar.utc_offset),
            stat.entered,
            stat.exited
          ))
        }
        _ -> #(model, effect.none())
      }
    }
  }
}
