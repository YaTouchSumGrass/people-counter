#include <WiFi.h>
#include "Stats.hpp"
#include <ArduinoJson.h>
#include <ESPAsyncWebServer.h>

// Change this to your actual SSID and password!
const char* SSID = "Bruh";
const char* PASS = "141592653";

void setupWiFi() {
    WiFi.mode(WIFI_STA);
    WiFi.begin(SSID, PASS);
    while (WiFi.status() != WL_CONNECTED) {
        delay(500);
    }
}

extern Stat globalStat;
AsyncWebServer server(80);

void setupServer() {
    setupWiFi();

    server.on("/api/stats", HTTP_GET, [](AsyncWebServerRequest* req) {
        JsonDocument doc;
        doc["entered"] = globalStat.entered;
        doc["exited"] = globalStat.exited;

        String json;
        serializeJson(doc, json);

        AsyncWebServerResponse* res = req->beginResponse(200, "app/json", json);
        res->addHeader("Acess-Control-Allow-Origin", "*");
        res->addHeader("Access-Control-Allow-Methods", "GET, OPTIONS");
        res->addHeader("Access-Control-Allow-Headers", "*");
        
        req->send(res);
    });

    server.onNotFound([](AsyncWebServerRequest* req) {
        if (req->method() == HTTP_OPTIONS) {
            AsyncWebServerResponse* res = req->beginResponse(204);
            res->addHeader("Acess-Control-Allow-Origin", "*");
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
