using Uno;
using Uno.Collections;
using Uno.Threading;
using Uno.IO;
using Fuse;
using Fuse.Scripting;
using Fuse.Reactive;
using Uno.Compiler.ExportTargetInterop;
using Bolav.ForeignHelpers;

// ios: https://www.dropbox.com/developers-v1/core/start/ios
// android: https://www.dropbox.com/developers-v1/core/sdks/android

[ForeignInclude(Language.Java, 
	"com.dropbox.client2.DropboxAPI", 
	"com.dropbox.client2.android.AndroidAuthSession", 
	"com.dropbox.client2.android.AuthActivity", 
	"com.dropbox.client2.session.AccessTokenPair", 
	"com.dropbox.client2.session.AppKeyPair",
	"com.fuse.Activity")]
[ForeignInclude(Language.ObjC, "FuseDBRCDelegate.h")]
[Require("Gradle.Dependencies.Compile","files('src/main/libs/dropbox-android-sdk-1.6.3.jar')")]
[Require("Gradle.Dependencies.Compile","files('src/main/libs/json_simple-1.1.jar')")]
public class Dropbox : NativeModule {

	public Dropbox () {
		// Add Load function to load image as a texture
		AddMember(new NativePromise<string, string>("link", Link, null));
		if defined(iOS) {
			AddMember(new NativePromise<ObjC.Object, Fuse.Scripting.Array>("metadata", Metadata, ConvertNSArray));
			AddMember(new NativePromise<string, string>("download", Download, null));
		}
		if defined(Android) {
			AddMember(new NativePromise<Java.Object, Fuse.Scripting.Array>("metadata", Metadata, ConvertJavaArray));
			AddMember(new NativePromise<string, string>("download", Download, null));
		}
	}

	extern(iOS) static Fuse.Scripting.Array ConvertNSArray(Context context, ObjC.Object result)
	{
		var ary = new JSList(context);
		ary.FromiOS(result);
		return ary.GetScriptingArray();
	}

	extern(Android) static Fuse.Scripting.Array ConvertJavaArray(Context context, Java.Object result) {
		debug_log "Converting results to js array";
		return null;
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

	extern(iOS) void OnReceivedUri(object sender, string uri) {
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

	bool inited_rc = false;
	bool md_inprogress = false;
	extern(iOS) Promise<ObjC.Object> md_promise;
	extern(Android) Promise<Java.Object> md_promise;

	extern(Mobile) void MDReject (string s) {
		// return unless md_inprogress?
		md_promise.Reject(new Exception(s));
		md_inprogress = false;
	}

	extern(iOS) void MDResolve (ObjC.Object o) {
		// return unless md_inprogress?
		md_promise.Resolve(o);
		md_inprogress = false;
	}

	extern(Android) void MDResolve (Java.Object o) {
		// return unless md_inprogress?
		md_promise.Resolve(o);
		md_inprogress = false;
	}

	extern(iOS) public void InitRestClient () {
		if (!inited_rc) {
			restClient = InitRestClientImpl();
			inited_rc = true;
		}
	}

	[Require("Entity","Dropbox.MDReject(string)")]
	[Require("Entity","Dropbox.MDResolve(ObjC.Object)")]
	extern(iOS) Future<ObjC.Object> Metadata (object[] args)
	{
		var p = new Promise<ObjC.Object>();
		if (md_inprogress) {
			p.Reject(new Exception("In progress"));
			return p;
		}
		md_inprogress = true;
		md_promise = p;
		var path = args[0] as string;
		if defined(iOS) InitRestClient();
		MetadataImpl(path);
		return md_promise;
	}

	extern(Android) Future<Java.Object> Metadata (object[] args)
	{
		var path = args[0] as string;
		var p = new MetaData(mdb_api, path);
		return p;
	}

	bool dl_inprogress = false;
	extern(Mobile) Promise<string> dl_promise;

	extern(Mobile) void DLReject (string s) {
		// return unless md_inprogress?
		dl_promise.Reject(new Exception(s));
		dl_inprogress = false;
	}

	extern(Mobile) void DLResolve (string s) {
		// return unless md_inprogress?
		dl_promise.Resolve(s);
		dl_inprogress = false;
	}

	[Require("Entity","Dropbox.DLReject(string)")]
	[Require("Entity","Dropbox.DLResolve(string)")]
	extern(Mobile) Future<string> Download (object[] args)
	{
		var p = new Promise<string>();
		if (dl_inprogress) {
			p.Reject(new Exception("In progress"));
			return p;
		}
		dl_inprogress = true;
		dl_promise = p;

		var from_file = args[0].ToString();
		var to_file = Path.Combine(Directory.GetUserDirectory(UserDirectory.Data), args[1].ToString());
		if defined(iOS) InitRestClient();
		DownloadImpl(from_file,to_file);
		return dl_promise;
	}

	extern(iOS) ObjC.Object restClient;

	[Foreign(Language.ObjC)]
	[Require("Source.Import","DropboxSDK/DropboxSDK.h")]
	extern(iOS) ObjC.Object InitRestClientImpl ()
	@{
		FuseDBRCDelegate *del = [[FuseDBRCDelegate alloc] init];
		[del setFuseDb:_this];
		DBRestClient *dbrc = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
		dbrc.delegate = del;
		return dbrc;

	@}

	[Foreign(Language.ObjC)]
	extern(iOS) void MetadataImpl (string path)
	@{
		::id dbrc = @{Dropbox:Of(_this).restClient:Get()};
		// Needs to run on main thread to get the callback from the delegate
		// https://www.dropboxforum.com/hc/en-us/community/posts/202269029--DBRestClient-loadFile-intoPath-doesn-t-call-callbacks-unless-a-timer-is-pending-on-iOS
		dispatch_async(dispatch_get_main_queue(), ^{
			[dbrc loadMetadata:path];
		});
	@}

	[Foreign(Language.ObjC)]
	extern(iOS) void DownloadImpl (string ff, string to)
	@{
		::id dbrc = @{Dropbox:Of(_this).restClient:Get()};
		dispatch_async(dispatch_get_main_queue(), ^{
			[dbrc loadFile:ff intoPath:to];
		});
	@}

	[Foreign(Language.ObjC)]
	extern(Android) void DownloadImpl (string ff, string to)
	@{
		return;
	@}

	public void Resolve(string s) {
	        link_promise.Resolve(s);
	}

	public void Reject(string s) {
	        link_promise.Reject(new Exception(s));
	}

	extern(!iOS) void LinkImpl() {
	}
	extern(!Mobile) void InitImpl(string key, string secret) {
	}

	extern(Android) Java.Object mdb_api;

	[Foreign(Language.Java)]
	extern(Android) void InitImpl(string key, string secret) 
	@{
		// In the class declaration section:
		DropboxAPI<AndroidAuthSession> mDBApi;

		// And later in some initialization function:
		AppKeyPair appKeys = new AppKeyPair(key, secret);
		AndroidAuthSession session = new AndroidAuthSession(appKeys);
		mDBApi = new DropboxAPI<AndroidAuthSession>(session);
		mDBApi.getSession().startOAuth2Authentication(Activity.getRootActivity());
		@{Dropbox:Of(_this).mdb_api:Set(mDBApi)};
	@}

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

	[ForeignInclude(Language.Java,
		"java.util.ArrayList",
		"java.util.Hashtable",
		"android.os.AsyncTask",
		"com.dropbox.client2.DropboxAPI",
		"com.dropbox.client2.DropboxAPI.Entry",
		"com.dropbox.client2.android.AndroidAuthSession", 
		"com.dropbox.client2.android.AuthActivity", 
		"com.dropbox.client2.session.AccessTokenPair", 
		"com.dropbox.client2.session.AppKeyPair",
		"com.dropbox.client2.exception.DropboxParseException",
		"com.dropbox.client2.exception.DropboxPartialFileException",
		"com.dropbox.client2.exception.DropboxIOException",
		"com.dropbox.client2.exception.DropboxException",
		"com.dropbox.client2.exception.DropboxServerException",
		"com.dropbox.client2.exception.DropboxUnlinkedException",
		"com.fuse.Activity")]
    extern(Android)
    class MetaData : Promise<Java.Object>
    {
        [Foreign(Language.Java)]
        public MetaData(Java.Object mdb_api, string path)
        @{

        	new AsyncTask<Void, Void, Boolean>() {
	        		ArrayList<Hashtable<String,String>> mList = new ArrayList<Hashtable<String,String>>();
    	    		String mErrorMsg = "";
        			DropboxAPI<AndroidAuthSession> mApi = (DropboxAPI<AndroidAuthSession>)mdb_api;

				    @Override
        	        protected Boolean doInBackground(Void... params) {
        	                try {
        	                    // Get the metadata for a directory
        	                    Entry dirent = mApi.metadata(path, 1000, null, true, null);

        	                    if (!dirent.isDir || dirent.contents == null) {
        	                        // It's not a directory, or there's nothing in it
        	                        mErrorMsg = "File or empty directory";
        	                        return false;
        	                    }

        	                    // Make a list of everything in it that we can get a thumbnail for
        	                    for (final Entry ent: dirent.contents) {
        	                    	Hashtable<String, String> ht = new Hashtable<String, String>() {{ 
        	                    		put("filename", ent.fileName()); 
        	                    		put("path", ent.path); 
        	                    	}};
        	                    	mList.add(ht);
        	                    }

        	                    return true;

        	                } catch (DropboxUnlinkedException e) {
        	                    // The AuthSession wasn't properly authenticated or user unlinked.
        	                } catch (DropboxPartialFileException e) {
        	                    // We canceled the operation
        	                    mErrorMsg = "Download canceled";
        	                } catch (DropboxServerException e) {
        	                    // Server-side exception.  These are examples of what could happen,
        	                    // but we don't do anything special with them here.
        	                    if (e.error == DropboxServerException._304_NOT_MODIFIED) {
        	                        // won't happen since we don't pass in revision with metadata
        	                    } else if (e.error == DropboxServerException._401_UNAUTHORIZED) {
        	                        // Unauthorized, so we should unlink them.  You may want to
        	                        // automatically log the user out in this case.
        	                    } else if (e.error == DropboxServerException._403_FORBIDDEN) {
        	                        // Not allowed to access this
        	                    } else if (e.error == DropboxServerException._404_NOT_FOUND) {
        	                        // path not found (or if it was the thumbnail, can't be
        	                        // thumbnailed)
        	                    } else if (e.error == DropboxServerException._406_NOT_ACCEPTABLE) {
        	                        // too many entries to return
        	                    } else if (e.error == DropboxServerException._415_UNSUPPORTED_MEDIA) {
        	                        // can't be thumbnailed
        	                    } else if (e.error == DropboxServerException._507_INSUFFICIENT_STORAGE) {
        	                        // user is over quota
        	                    } else {
        	                        // Something else
        	                    }
        	                    // This gets the Dropbox error, translated into the user's language
        	                    mErrorMsg = e.body.userError;
        	                    if (mErrorMsg == null) {
        	                        mErrorMsg = e.body.error;
        	                    }
        	                } catch (DropboxIOException e) {
        	                    // Happens all the time, probably want to retry automatically.
        	                    mErrorMsg = "Network error.  Try again.";
        	                } catch (DropboxParseException e) {
        	                    // Probably due to Dropbox server restarting, should retry
        	                    mErrorMsg = "Dropbox error.  Try again.";
        	                } catch (DropboxException e) {
        	                    // Unknown error
        	                    mErrorMsg = "Unknown error.  Try again.";
        	                }
        	                // 
        	                return false;
        	        }
        	        @Override
        	        protected void onPostExecute(Boolean result) {
       	                if (result) {
       	                    // resolve promise
      	                    @{MetaData:Of(_this).Resolve(Java.Object):Call(mList)};
       	                } else {
       	                    @{MetaData:Of(_this).SReject(string):Call(mErrorMsg)};
       	                }
        	        }
        	}.execute();

        @}

        public void SReject(string reason)
        {
            Reject(new Exception(reason));
        }
    }



