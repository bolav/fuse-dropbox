using Uno;
using Uno.Collections;
using Fuse;
using Fuse.Scripting;
using Fuse.Reactive;
using Uno.Compiler.ExportTargetInterop;

public class Dropbox : NativeModule {

	public Dropbox () {
		// Add Load function to load image as a texture
		debug_log "Dropbox";
		AddMember(new NativeFunction("login", (NativeCallback)Login));
	}

	bool inited = false;

	void Init (string key, string secret) {
		if (inited) {
			return;
		}
		if defined(iOS) {
			debug_log "Registering callback";
			Uno.Platform2.Application.ReceivedURI += OnReceivedUri;
		}

		InitImpl(key, secret);
		inited = true;
	}

	static void OnReceivedUri(object sender, string uri) {
	    debug_log uri;
	    // if (uri.Substring(0,2) == "fb")
	    //    Register(uri);
	}

	object Login (Context c, object[] args)
	{
		var key = args[0] as string;
		var secret = args[1] as string;
		Init(key, secret);
		LinkImpl();
		return null;
	}

	[Foreign(Language.ObjC)]
	[Require("Source.Import","DropboxSDK/DropboxSDK.h")]
	extern(iOS) void InitImpl (string key, string secret)
	@{
		DBSession *dbSession = [[DBSession alloc]
		      initWithAppKey:key
		      appSecret:secret
		      root:kDBRootAppFolder]; // either kDBRootAppFolder or kDBRootDropbox
	@}


	// https://www.dropbox.com/developers-v1/core/start/ios
	[Foreign(Language.ObjC)]
	extern(iOS) void LinkImpl ()
	@{
		::id kw = [[UIApplication sharedApplication] keyWindow];
		if (![[DBSession sharedSession] isLinked]) {
		    [[DBSession sharedSession] linkFromController:kw];
		}
	@}




}
