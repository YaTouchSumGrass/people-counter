import gleam/int
import gleam/order
import gleam/time/calendar
import gleam/time/timestamp
import gleam/io
import model.{
  type Model, Model,
  type Msg,
  OnReceiveMessage,
  GotSessionGetResponse, GotSessionPostResponse,
  GotEventGetResponse, GotEventPostResponse,
  ArchiveSession
}
import gleam/option.{Some, None}
import lustre/effect.{type Effect}
import lustre_websocket as ws
import db


pub fn connect_esp32() -> #(Model, Effect(Msg)) {
  #(
    Model(
      started: timestamp.from_unix_seconds(0),
      stat: None,
      previous_stat: None,
      socket: None,
      events: [],
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
          let previous_stat = model.stat
          let stat = model.decode_stat(text)

          let effect = case previous_stat, stat {
            Some(prev), Some(st) -> {
              case int.compare(st.entered, prev.entered) {
                order.Gt -> db.write_events(
                  "Entered",
                  timestamp.system_time()
                  |> timestamp.to_rfc3339(calendar.utc_offset)
                )
                _ -> case int.compare(st.exited, prev.exited) {
                  order.Gt -> db.write_events(
                    "Exited",
                    timestamp.system_time()
                    |> timestamp.to_rfc3339(calendar.utc_offset)
                  )
                  _ -> effect.none()
                }
              }
            }
            _, _ -> effect.none()
          }

          #(Model(..model, stat: stat, previous_stat: previous_stat), effect)
        }

        ws.InvalidUrl -> {
          io.println("Invalid WebSocket URL!")
          #(model, effect.none())
        }

        _ -> #(model, effect.none())
      }
    }

    GotSessionGetResponse(result) -> {
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

    GotSessionPostResponse(result) -> {
      case model.socket, result {
        Some(socket), Ok(response) -> {
          case response.status {
            201 -> {
              #(model, effect.batch([
                db.fetch_sessions(),
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

    GotEventGetResponse(result) -> {
      case result {
        Ok(events) -> #(
          Model(..model, events: events),
          effect.none()
        )
        Error(err) -> {
          echo err
          #(model, effect.none())
        }
      }
    }

    GotEventPostResponse(result) -> {
      case result {
        Ok(response) -> {
          case response.status {
            201 -> #(model, db.fetch_events())
            _ -> #(model, effect.none())
          }
        }
        Error(err) -> {
          echo err
          #(model, effect.none())
        }
      }
    }

    ArchiveSession(ended) -> {
      case model.stat {
        Some(stat) -> {
          #(model, db.write_sessions(
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
