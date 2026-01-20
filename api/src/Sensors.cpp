#include "Sensors.hpp"
#include "Server.hpp"
#include "HardwareSerial.h"
#include <Arduino.h>

// Feel free to adjust these!
const unsigned long SEQ_TIMEOUT = 1500;
const unsigned long STOP_LISTEN_TIME = 300;
const unsigned long PIR_ACTIVE_WINDOW = 3000;

IRState irState = IRState::Idle;
unsigned long irStateTime = 0;

PIRState pirState = {
    .active = false,
    .lastTriggered = 0
};


void updateIR(Stat* stat, bool irA, bool irB) {
    unsigned long now = millis();
    if (now - irStateTime < STOP_LISTEN_TIME) return;

    switch (irState) {
        case IRState::Idle: {
            if (irA) {
                irState = IRState::IRATriggered;
                irStateTime = now;
            }
            else if (irB) {
                irState = IRState::IRBTriggered;
                irStateTime = now;
            }
            break;
        }
        case IRState::IRATriggered: {
            if (irB && pirState.active) {
                stat->entered++;
                updateStats();
                irState = IRState::Idle;
            }
            else if (now - irStateTime > SEQ_TIMEOUT) {
                irState = IRState::Idle;
            }
            break;
        }
        case IRState::IRBTriggered: {
            if (irA && pirState.active) {
                stat->exited++;
                updateStats();
                irState = IRState::Idle;
            }
            else if (now - irStateTime > SEQ_TIMEOUT) {
                irState = IRState::Idle;
            }
            break;
        }
    }
}

void updatePIR(bool pir) {
    if (pir) {
        pirState.active = true;
        pirState.lastTriggered = millis();
    }
    else if (pirState.active && millis() - pirState.lastTriggered > PIR_ACTIVE_WINDOW) {
        pirState.active = false;
    }
}
