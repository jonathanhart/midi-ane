//
//  MIDIAgent.cpp
//  MIDIANE
//
//  Created by Jonathan on 5/19/13.
//  Copyright (c) 2013 Numeda. All rights reserved.
//

#include "MIDIAgent.h"
#include <Adobe AIR/Adobe AIR.h>

static NSString* getDisplayName(MIDIObjectRef object)
{
    // Returns the display name of a given MIDIObjectRef as an NSString
    CFStringRef name = nil;
    MIDIObjectGetStringProperty(object, kMIDIPropertyDisplayName, &name);
    return (NSString*)name;
}

static uint8_t* convertStringToUInt8_t (NSString* inString) {
    return (uint8_t*)[inString UTF8String];
}

// main dispatcher
static int tick;
static int beats;
static int measures;
static int doublemeasures;
static int halfphrases;
static int phrases;
static int halfnotes;
static int modtick;

static FREContext _context;

static void dispatch(FREContext context, uint8_t* eventCode, uint8_t* eventLevel)
{
    if (context) {
        FREDispatchStatusEventAsync(context, eventCode, eventLevel);
    }
}

static void customLog(NSString* text) {
    dispatch(_context, convertStringToUInt8_t(@"LOG"), convertStringToUInt8_t(text));
}

static void midiInputCallback (const MIDIPacketList *list,
                        void *procRef,
                        void *srcRef)
{
    NSString* eventCode = @"0";
    NSString* eventLevel = @"0";
    
    MIDIPacket* packet;
    packet = MIDIPacketListInit((MIDIPacketList*)list);
    
    int status = packet->data[0];
    int value = packet->data[1];
    int rest = packet->data[2];
    
    int channel = 0;
    switch (status) {
        case 0xf8: // Clock tick
            if(tick%12==0) {
                if(tick%24==0)
                {
                    if(beats%4==0) {
                        if(measures%2==0) {
                            if(doublemeasures%2==0){
                                if(halfphrases%2==0) {
                                    if(phrases%2==0){
                                        // wee megaphrases
                                        eventCode = @"MEGAPHRASE";
                                        dispatch(_context, convertStringToUInt8_t(eventCode), convertStringToUInt8_t(eventLevel));
                                    }
                                    phrases++;
                                    eventCode = @"PHRASE";
                                    dispatch(_context, convertStringToUInt8_t(eventCode), convertStringToUInt8_t(eventLevel));
                                }
                                halfphrases++;
                                eventCode = @"HALFPHRASE";
                                dispatch(_context, convertStringToUInt8_t(eventCode), convertStringToUInt8_t(eventLevel));
                            }
                            doublemeasures++;
                            eventCode = @"DOUBLEMEASURE";
                            dispatch(_context, convertStringToUInt8_t(eventCode), convertStringToUInt8_t(eventLevel));
                        }
                        measures++;
                        eventCode = @"MEASURE";
                        dispatch(_context, convertStringToUInt8_t(eventCode), convertStringToUInt8_t(eventLevel));
                    }
                    beats++;
                    eventCode = @"BEAT";
                    dispatch(_context, convertStringToUInt8_t(eventCode), convertStringToUInt8_t(eventLevel));
                    
                    if (beats%2==1)
                    {
                        eventCode = @"SNARE";
                        dispatch(_context, convertStringToUInt8_t(eventCode), convertStringToUInt8_t(eventLevel));
                    }
                }
                halfnotes++;
                if (halfnotes%2==1) {
                    eventCode = @"HIHAT";
                    dispatch(_context, convertStringToUInt8_t(eventCode), convertStringToUInt8_t(eventLevel));
                }
            }
            tick++;
            break;
        case 0xfa:
            modtick=0;
            tick=0;
            beats=0;
            measures=0;
            doublemeasures=0;
            halfphrases=0;
            phrases=0;
            eventCode = @"RESET";
            dispatch(_context, convertStringToUInt8_t(eventCode), convertStringToUInt8_t(eventLevel));
            break;
        default:
        {
            channel = status & 0x0f;
            int message = status & 0xf0;
            switch (message) {
                case 0x80: // note off
                    eventCode = @"NOTEOFF";
                    value+=32;
                    break;
                case 0x90: // note on
                    eventCode = @"NOTEON";
                    break;
                case 0xa0: // key pressure
                    eventCode = @"KEYPRESSURE";
                    break;
                case 0xb0: // CC change
                    eventCode = @"CC";
                    break;
                case 0xc0: // program change
                    eventCode = @"PROGRAMCHANGE";
                    break;
                case 0xd0: // channel pressure
                    eventCode = @"CHANNELPRESSURE";
                    break;
                case 0xe0: // pitch bend
                    eventCode = @"PITCHBEND";
                    break;
            }
            eventLevel = [NSString stringWithFormat:@"%d/%d/%d", channel, value, rest];
            dispatch(_context, convertStringToUInt8_t(eventCode), convertStringToUInt8_t(eventLevel));
            break;
        }
    }
}

void ClientNotifyProc(const MIDINotification * message, void *refCon)
{
    NSLog([NSString stringWithFormat:@"id: %d",message->messageID]);
}

uint32_t MIDIAgent::addMIDIDeviceListener(std::string deviceName)
{
    uint32_t success = 1;
    
    MIDIEndpointRef source = nil;
    
    ItemCount sourceCount = MIDIGetNumberOfSources();
    
    NSLog(@"Checking %ld devices for %s", sourceCount, deviceName.c_str());
    for(ItemCount i=0;i<sourceCount; i++){
        source = MIDIGetSource(i);
        NSString* sourceName = getDisplayName(source);
        NSLog(@"Found %@", sourceName);
        if ([sourceName isEqualToString:[NSString stringWithUTF8String:deviceName.c_str()]]) {
            NSLog(@"found!");
            break;
        }
    }
    
    OSStatus ossResult = noErr;
    
    if (source) {
        // create port and client
        if (!_midiClient) {
            NSLog(@"Creating MIDI Client");
            ossResult = MIDIClientCreate(CFSTR("MIDI client"), ClientNotifyProc, NULL, &_midiClient);
        }
        
        if (ossResult != noErr) {
            NSLog(@"MIDI Client Creation Error");
            success = 0;
        } else {
            if (!_inputPort) {
                NSLog(@"Creating input port");
                ossResult = MIDIInputPortCreate(_midiClient, CFSTR("Input Port"), midiInputCallback, NULL, &_inputPort);
            }
            
            if (ossResult != noErr) {
                NSLog(@"MIDI Input Port Creation Error");
                success = 0;
            }
            if (!source) {
                NSLog(@"source is null");
            }
            ossResult = MIDIPortConnectSource(_inputPort, source, NULL);
        }
    }
    return success;
}

std::vector<std::string> MIDIAgent::getMIDIDeviceListeners () {
    std::vector<std::string> returnVector;
    
    for (int i=0; i<[_clientArray count]; i++) {
        MIDIClientRef ref = (MIDIClientRef)[_clientArray objectAtIndex:i];
        CFStringRef refName;
        MIDIObjectGetStringProperty(ref, CFSTR("name"), &refName);
        returnVector.push_back(std::string((const char*)refName));
    }
    
    return returnVector;
}

MIDIAgent::MIDIAgent(FREContext context) : _midiClient(NULL), _clientArray(NULL), _inputPort(NULL) {
    _context = context;
}

MIDIAgent::~MIDIAgent()
{
    NSLog(@"MIDIAgent::~Destructor");
}

void MIDIAgent::dispose()
{
    if (_clientArray) {
        for (int i=0;i<[_clientArray count];i++) {
            MIDIEndpointRef ref = (MIDIEndpointRef)[_clientArray objectAtIndex:i];
            MIDIPortDisconnectSource(_inputPort, ref);
            MIDIEndpointDispose(ref);
        }
    }
    MIDIClientDispose(_midiClient);
    [_clientArray release];
    _clientArray = NULL;
}
