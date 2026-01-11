#include <WiFi.h>
#include "AsyncWebSocket.h"
#include "Stats.hpp"
#include <ArduinoJson.h>
#include <ESPAsyncWebServer.h>

void setupWiFi() {
    WiFi.mode(WIFI_AP);
    WiFi.softAP("ESP32_DoorCounter", "Skibidi67TungTungSahur");
}

extern Stat globalStat;
AsyncWebServer server(80);
AsyncWebSocket ws("/ws");

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
            Serial.println("WS client connected");
            break;

        case WS_EVT_DISCONNECT:
            Serial.println("WS client disconnected");
            break;

        case WS_EVT_ERROR:
            Serial.println("WS error");
            break;

        case WS_EVT_DATA:
            Serial.println("WS data received");
            break;
    }
}

void updateStats() {
    JsonDocument doc;
    doc["entered"] = globalStat.entered;
    doc["exited"] = globalStat.exited;

    String json;
    serializeJson(doc, json);
    ws.textAll(json);
}

void setupServer() {
    setupWiFi();

    delay(100);

    ws.onEvent(onWSEvent);
    server.addHandler(&ws);

    server.on("/api/stats", HTTP_GET, [](AsyncWebServerRequest* req) {
        JsonDocument doc;
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
