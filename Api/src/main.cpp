#include <Arduino.h>
#include "Stats.hpp"
#include "Sensors.hpp"
#include "Server.hpp"

const int IRA_PIN = 32;
const int IRB_PIN = 33;
const int PIR_PIN = 34;

Stat globalStat = {
    .entered = 0,
    .exited = 0
};

void setup() {
    Serial.begin(115200);
    pinMode(IRA_PIN, INPUT);
    pinMode(IRB_PIN, INPUT);
    pinMode(PIR_PIN, INPUT);
    setupServer();
}

void loop() {
    bool irA = analogRead(IRA_PIN) <= 4000;
    bool irB = analogRead(IRB_PIN) <= 4000;
    bool pir = digitalRead(PIR_PIN);
    updatePIR(pir);
    updateIR(&globalStat, irA, irB);
}
