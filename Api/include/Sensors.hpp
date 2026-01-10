#pragma once
#include "Stats.hpp"

enum class IRState {
    Idle,
    IRATriggered,
    IRBTriggered,
};

struct PIRState {
    bool active;
    unsigned long lastTriggered;
};

void updateIR(Stat* stat, bool irA, bool irB);

void updatePIR(bool pir);
