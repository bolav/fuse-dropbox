#import "FuseDBRCDelegate.h"
@{Dropbox:IncludeDirective}

@implementation FuseDBRCDelegate

- (void)restClient:(DBRestClient *)client uploadedFile:(NSString *)destPath
    from:(NSString *)srcPath metadata:(DBMetadata *)metadata {
    NSLog(@"File uploaded successfully to path: %@", metadata.path);
}

- (void)restClient:(DBRestClient *)client uploadFileFailedWithError:(NSError *)error {
    NSLog(@"File upload failed with error: %@", error);
}

- (void)restClient:(DBRestClient *)client loadedMetadata:(DBMetadata *)metadata {
    NSMutableArray *ary = [[NSMutableArray alloc] init];
    if (metadata.isDirectory) {
        for (DBMetadata *file in metadata.contents) {
            NSDictionary *dict = \\@{
                @"filename" : file.filename,
                @"path"     : file.path
            };
            [ary addObject:dict];
        }
    }
    @{Dropbox:Of(self.fuseDb).MDResolve(ObjC.Object):Call(ary)};
}

- (void)restClient:(DBRestClient *)client
    loadMetadataFailedWithError:(NSError *)error {
    NSLog(@"Error loading metadata: %@", error);
    @{Dropbox:Of(self.fuseDb).MDReject(string):Call(error.localizedDescription)};
}

@end