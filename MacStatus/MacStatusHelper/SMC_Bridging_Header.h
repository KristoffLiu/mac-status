#ifndef SMC_Bridging_Header_h
#define SMC_Bridging_Header_h

#import <Foundation/Foundation.h>
#import <IOKit/IOKitLib.h>

enum {
    kSMCUserClientOpen  = 0,
    kSMCUserClientClose = 1,
    kSMCHandleYPCEvent  = 2,
    kSMCReadKey         = 5,
    kSMCWriteKey        = 6,
    kSMCGetKeyCount     = 7,
    kSMCGetKeyFromIndex = 8,
    kSMCGetKeyInfo      = 9
};

typedef struct {
    unsigned char    major;
    unsigned char    minor;
    unsigned char    build;
    unsigned char    reserved[1];
    unsigned short   release;
} SMCVersion;

typedef struct {
    uint16_t  version;
    uint16_t  length;
    uint32_t  cpuPLimit;
    uint32_t  gpuPLimit;
    uint32_t  memPLimit;
} SMCPLimitData;

typedef struct {
    uint32_t  dataSize;
    uint32_t  dataType;
    uint8_t   dataAttributes;
} SMCKeyInfoData;

typedef char SMCBytes[32];

typedef struct {
    uint32_t        key;
    SMCVersion      vers;
    SMCPLimitData   pLimitData;
    SMCKeyInfoData  keyInfo;
    uint8_t         result;
    uint8_t         status;
    uint8_t         data8;
    uint32_t        data32;
    SMCBytes        bytes;
} SMCParamStruct;

#endif /* SMC_Bridging_Header_h */
