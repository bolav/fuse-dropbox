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

- (void)restClient:(DBRestClient *)client loadedFile:(NSString *)localPath
    contentType:(NSString *)contentType metadata:(DBMetadata *)metadata {
    NSLog(@"File loaded into path: %@", localPath);
    NSLog(@"File loaded metadata:  %@", metadata);
    @{Dropbox:Of(self.fuseDb).DLResolve(string):Call(localPath)};
}

- (void)restClient:(DBRestClient *)client loadFileFailedWithError:(NSError *)error {
    NSLog(@"There was an error loading the file: %@", error);
    @{Dropbox:Of(self.fuseDb).DLReject(string):Call(error.localizedDescription)};
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