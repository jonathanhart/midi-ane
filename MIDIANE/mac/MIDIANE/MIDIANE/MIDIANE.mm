//
//  MIDIANE.m
//  MIDIANE
//
//  Created by Jonathan on 4/9/13.
//  Copyright (c) 2013 Numeda. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Adobe AIR/Adobe AIR.h>
#import "CoreMIDI/CoreMIDI.h"

#include "MIDIAgent.h"

extern "C" {

    MIDIAgent* _agent;
    
    void redirectConsoleLogToDocumentFolder ()
    {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                             NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *logPath = [documentsDirectory stringByAppendingPathComponent:@"console.log"];
        freopen([logPath fileSystemRepresentation],"a+",stderr);
    }

    uint8_t* convertStringToUInt8_t (NSString* inString) {
        return (uint8_t*)[inString UTF8String];
    }

    void dispatch(FREContext context, uint8_t* eventCode, uint8_t* eventLevel)
    {
        if (context) {
            FREDispatchStatusEventAsync(context, eventCode, eventLevel);
        }
    }

    NSString* getDisplayName(MIDIObjectRef object)
    {
        // Returns the display name of a given MIDIObjectRef as an NSString
        CFStringRef name = nil;
        MIDIObjectGetStringProperty(object, kMIDIPropertyDisplayName, &name);
        return (NSString*)name;
    }

    FREObject getMIDIDeviceList(FREContext ctx, void* funcData, uint32_t argc, FREObject argv[]) {
        FREObject result;
        
        FRENewObject((const uint8_t*)"Array", 0, NULL, &result, nil);
        
        MIDIEndpointRef source;
        ItemCount sourceCount = MIDIGetNumberOfSources();
        
        FRESetArrayLength(result, sourceCount);
        
        for(ItemCount i=0;i<sourceCount; i++){
            source = MIDIGetSource(i);
            FREObject sourceObject;
            NSString* sourceName = getDisplayName(source);
            FRENewObjectFromUTF8([sourceName length], convertStringToUInt8_t(sourceName), &sourceObject);
            FRESetArrayElementAt(result, i, sourceObject);
        }
        
        return result;
    }


    FREObject addMIDIDeviceListener(FREContext ctx, void* funcData, uint32_t argc, FREObject argv[])
    {
        FREObject result;
        
        // obtain device name
        uint32_t len;
        
        unsigned const char* deviceName;
        FREGetObjectAsUTF8(argv[0], &len, &deviceName);
        
        uint32_t success = _agent->addMIDIDeviceListener(std::string(reinterpret_cast<const char*>(deviceName)));
        FRENewObjectFromUint32(success, &result);
        return result;
    }

    FREObject getMIDIDeviceListeners(FREContext ctx, void* funcData, uint32_t argc, FREObject argv[]) {
        FREObject result;
        
        FRENewObject((const uint8_t*)"Array", 0, NULL, &result, nil);
        
        return result;
    }

    FREObject isSupported(FREContext ctx, void* funcData, uint32_t argc, FREObject argv[]) {
        FREObject result;
        
        uint32_t isSupportedSwitch = 1;
        FRENewObjectFromBool(isSupportedSwitch, &result);
        
        return result;
    }


    void MIDIANE_ContextInitializer(void* extData, const uint8_t* ctxType, FREContext ctx, uint32_t* numFunctionsToSet, const FRENamedFunction** functionsToSet){

        int functions = 4;
        
        *numFunctionsToSet = functions;
        
        FRENamedFunction* func = (FRENamedFunction*)malloc(sizeof(FRENamedFunction)* functions);
        
        func[0].name = (const uint8_t*)"getMIDIDeviceList";
        func[0].functionData = NULL;
        func[0].function = &getMIDIDeviceList;
        
        func[1].name = (const uint8_t*)"getMIDIDeviceListeners";
        func[1].functionData = NULL;
        func[1].function = &getMIDIDeviceListeners;
        
        func[2].name = (const uint8_t*)"addMIDIDeviceListener";
        func[2].functionData = NULL;
        func[2].function = &addMIDIDeviceListener;
        
        func[3].name = (const uint8_t*)"isSupported";
        func[3].functionData = NULL;
        func[3].function = &isSupported;

        *functionsToSet = func;
        
        _agent = new MIDIAgent(ctx);
    }

    void MIDIANE_ContextFinalizer(FREContext ctx)
    {
        NSLog(@"FINALIZING");
        NSLog(@"%@",[NSThread callStackSymbols]);
        _agent->dispose();
        return;
    }

    void MIDIANEInitializer(void** extDataToSet, FREContextInitializer* ctxInitializerToSet, FREContextFinalizer* ctxFinalizerToSet){
        extDataToSet = NULL;
        *ctxInitializerToSet = &MIDIANE_ContextInitializer;
        *ctxFinalizerToSet = &MIDIANE_ContextFinalizer;
        redirectConsoleLogToDocumentFolder();
    }

    void MIDIANEFinalizer (FREContext ctx) {
    }
}
