#import <DropboxSDK/DropboxSDK.h>
#include <uObjC.Foreign.h>

@interface FuseDBRCDelegate : NSObject<DBRestClientDelegate>

@property (nonatomic, retain) id<UnoObject> fuseDb;

@end
