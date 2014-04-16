//
//  MIDIAgent.h
//  MIDIANE
//
//  Created by Jonathan on 5/19/13.
//  Copyright (c) 2013 Numeda. All rights reserved.
//

#pragma once

#include <vector>
#include <string>
#include <iostream>
#include <CoreMIDI/CoreMIDI.h>
#include <Adobe AIR/Adobe AIR.h>

class MIDIAgent {

public:
    MIDIAgent(FREContext context);
    uint32_t addMIDIDeviceListener(std::string device);
    std::vector<std::string> getMIDIDeviceList();
    std::vector<std::string> getMIDIDeviceListeners();
    void dispose();
    
private:
    ~MIDIAgent();
    MIDIClientRef _midiClient;
    NSMutableArray* _clientArray;
    MIDIPortRef _inputPort; 
};