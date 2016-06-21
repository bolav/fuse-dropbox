using Uno;
using Uno.Collections;
using Uno.Threading;
using Fuse;
using Fuse.Scripting;
using Fuse.Reactive;
using Uno.Compiler.ExportTargetInterop;

public class Dropbox : NativeModule {

	public Dropbox () {
		// Add Load function to load image as a texture
		AddMember(new NativePromise<string, string>("link", Link, null));
	}

	bool inited = false;

	void Init (string key, string secret) {
		if (inited) {
			return;
		}
		if defined(iOS) {
			Uno.Platform2.Application.ReceivedURI += OnReceivedUri;
		}

		InitImpl(key, secret);
		inited = true;
	}

	void OnReceivedUri(object sender, string uri) {
	    debug_log uri;
	    if (uri.Substring(0,2) == "db")
	       LinkCBImpl(uri);
	}

	Promise<string> link_promise;
	Future<string> Link (object[] args)
	{
		link_promise = new Promise<string>();
		var key = args[0] as string;
		var secret = args[1] as string;
		Init(key, secret);
		LinkImpl();
		return link_promise;
	}

	public void Resolve(string s) {
	        link_promise.Resolve(s);
	}

	public void Reject(string s) {
	        link_promise.Reject(new Exception(s));
	}

	[Foreign(Language.ObjC)]
	[Require("Source.Import","DropboxSDK/DropboxSDK.h")]
	extern(iOS) void InitImpl (string key, string secret)
	@{
		DBSession *dbSession = [[DBSession alloc]
		      initWithAppKey:key
		      appSecret:secret
		      root:kDBRootAppFolder]; // either kDBRootAppFolder or kDBRootDropbox
		[DBSession setSharedSession:dbSession];
	@}


	// https://www.dropbox.com/developers-v1/core/start/ios
	[Foreign(Language.ObjC)]
	extern(iOS) void LinkImpl ()
	@{
		::id rvc = [[[UIApplication sharedApplication] keyWindow] rootViewController];
		if (![[DBSession sharedSession] isLinked]) {
		    [[DBSession sharedSession] linkFromController:rvc];
		}
		else {
			@{Dropbox:Of(_this).Resolve(string):Call(@"already")};
		}
	@}

	[Foreign(Language.ObjC)]
	extern(iOS) void LinkCBImpl (string uri)
	@{
		NSURL *url = [[NSURL alloc] initWithString:uri];
		if ([[DBSession sharedSession] handleOpenURL:url]) {
		    if ([[DBSession sharedSession] isLinked]) {
		        @{Dropbox:Of(_this).Resolve(string):Call(@"success")};
		        return;
		    }
		    @{Dropbox:Of(_this).Reject(string):Call(@"fail")};
		    return;
		}
	@}





}
