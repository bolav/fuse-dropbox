
package no.ikke.fuse.dropbox;

@{JavaPromiseClosure:IncludeDirective}

import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Hashtable;

import android.os.AsyncTask;

import com.dropbox.client2.DropboxAPI;
import com.dropbox.client2.DropboxAPI.Entry;
import com.dropbox.client2.DropboxAPI.ThumbFormat;
import com.dropbox.client2.DropboxAPI.ThumbSize;
import com.dropbox.client2.exception.DropboxException;
import com.dropbox.client2.exception.DropboxIOException;
import com.dropbox.client2.exception.DropboxParseException;
import com.dropbox.client2.exception.DropboxPartialFileException;
import com.dropbox.client2.exception.DropboxServerException;
import com.dropbox.client2.exception.DropboxUnlinkedException;

public class DBMetaData extends AsyncTask<Void, Long, Boolean> {


    private DropboxAPI<?> mApi;
    private com.uno.UnoObject mPromise;
    private String mPath;
    private String mErrorMsg;
    private ArrayList<Hashtable<String,String>> mList;

    public DBMetaData(DropboxAPI<?> api,
            String dropboxPath, com.uno.UnoObject promise) {
        mApi = api;
        mPath = dropboxPath;
        mPromise = promise;
        mList = new ArrayList<Hashtable<String,String>>();
    }

    @Override
    protected Boolean doInBackground(Void... params) {
        try {
            // Get the metadata for a directory
            Entry dirent = mApi.metadata(mPath, 1000, null, true, null);

            if (!dirent.isDir || dirent.contents == null) {
                // It's not a directory, or there's nothing in it
                mErrorMsg = "File or empty directory";
                return false;
            }

            // Make a list of everything in it that we can get a thumbnail for
            for (Entry ent: dirent.contents) {
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
            // Set the image now that we have it

            // resolve promise
            @{JavaPromiseClosure:Of(mPromise).Resolve(Java.Object):Call(mList)};
        } else {
            // Couldn't download it, so show an error

            @{JavaPromiseClosure:Of(mPromise).Reject(string):Call(mErrorMsg)};
        }
    }
}
