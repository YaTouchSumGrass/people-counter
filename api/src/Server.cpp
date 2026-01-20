#include <WiFi.h>
#include "AsyncWebSocket.h"
#include "Stats.hpp"
#include <ArduinoJson.h>
#include <ESPAsyncWebServer.h>

void setupWiFi() {
    WiFi.mode(WIFI_AP);
    // You can change the WiFi name and password here!
    WiFi.softAP("ESP32_PeopleCounter", "Skibidi67TungTungSahur");
}

extern Stat globalStat;
AsyncWebServer server(80);
AsyncWebSocket ws("/ws");

void updateStats() {
    JsonDocument doc;
    doc["boot_id"] = globalStat.boot_id;
    doc["entered"] = globalStat.entered;
    doc["exited"] = globalStat.exited;
    
    Serial.print("Entered: ");
    Serial.println(globalStat.entered);
    Serial.print("Exited: ");
    Serial.println(globalStat.exited);

    String json;
    serializeJson(doc, json);
    ws.textAll(json);
}

void archiveSession() {
    Serial.println("Archive session message received.");
    globalStat.entered = 0;
    globalStat.exited = 0;
    updateStats();
}

void onWSEvent(
    AsyncWebSocket* server,
    AsyncWebSocketClient* client,
    AwsEventType type,
    void* arg,
    uint8_t* data,
    size_t len
) {
    switch (type) {
        case WS_EVT_CONNECT:
            Serial.println("WebSocket client connected.");
            break;

        case WS_EVT_DISCONNECT:
            Serial.println("WebSocket client disconnected.");
            break;

        case WS_EVT_ERROR:
            Serial.println("WebSocket client error.");
            break;

        case WS_EVT_DATA: {
            AwsFrameInfo* info = (AwsFrameInfo*)arg;
            if (info->final && info->index == 0 && info->len == len && info->opcode == WS_TEXT) {
                data[len] = 0;
                String message = (char*)data;
                if (message == "ARCHIVE") {
                    archiveSession();
                }
                else {
                    Serial.println("Invalid message received. Ignoring.");
                }
            }
            break;
        }
    }
}


void setupServer() {
    setupWiFi();

    delay(100);

    ws.onEvent(onWSEvent);
    server.addHandler(&ws);

    server.on("/api/stats", HTTP_GET, [](AsyncWebServerRequest* req) {
        JsonDocument doc;
        doc["boot_id"] = globalStat.boot_id;
        doc["entered"] = globalStat.entered;
        doc["exited"] = globalStat.exited;

        String json;
        serializeJson(doc, json);

        AsyncWebServerResponse* res = req->beginResponse(200, "application/json", json);
        res->addHeader("Access-Control-Allow-Origin", "*");
        res->addHeader("Access-Control-Allow-Methods", "GET, OPTIONS");
        res->addHeader("Access-Control-Allow-Headers", "*");
        
        req->send(res);
    });

    server.onNotFound([](AsyncWebServerRequest* req) {
        if (req->method() == HTTP_OPTIONS) {
            AsyncWebServerResponse* res = req->beginResponse(204);
            res->addHeader("Access-Control-Allow-Origin", "*");
            res->addHeader("Access-Control-Allow-Methods", "GET, OPTIONS");
            res->addHeader("Access-Control-Allow-Headers", "*");
        
            req->send(res);
        }
        else {
            req->send(404);
        }
    });

    server.begin();
}

void cleanupClients() {
    ws.cleanupClients();
}

