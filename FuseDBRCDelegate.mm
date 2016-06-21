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
    if (metadata.isDirectory) {
        NSLog(@"Folder '%@' contains:", metadata.path);
        for (DBMetadata *file in metadata.contents) {
            NSLog(@"	%@", file.filename);
        }
    }
    NSArray *currencies = @[@"Dollar", @"Euro", @"Pound"];
    @{Dropbox:Of(self.fuseDb).MDResolve(ObjC.Object):Call(currencies)};

}

- (void)restClient:(DBRestClient *)client
    loadMetadataFailedWithError:(NSError *)error {
    NSLog(@"Error loading metadata: %@", error);
}

@end