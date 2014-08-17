/*
THIS SOFTWARE IS PROVIDED BY ANDREW TRICE "AS IS" AND ANY EXPRESS OR
IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
EVENT SHALL ANDREW TRICE OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
package com.blakgeek.cordova.plugin;

import android.content.Context;
import android.content.res.AssetFileDescriptor;
import android.content.res.AssetManager;
import android.media.AudioManager;
import android.media.SoundPool;
import android.util.Log;
import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.PluginResult;
import org.apache.cordova.PluginResult.Status;
import org.json.JSONArray;
import org.json.JSONException;
import com.blakgeek.cordova.plugin.LowLatencyAudioAsset;

import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

/**
 * @author Andrew Trice
 */
public class LowLatencyAudio extends CordovaPlugin {

    public static final String ERROR_NO_AUDIOID = "A reference does not exist for the specified audio id.";
    private static final PluginResult RESULT_NO_AUDIOID = new PluginResult(Status.ERROR, ERROR_NO_AUDIOID);
    public static final String ERROR_AUDIOID_EXISTS = "A reference already exists for the specified audio id.";
    private static final PluginResult RESULT_AUDIOID_EXISTS = new PluginResult(Status.ERROR, ERROR_AUDIOID_EXISTS);

    public static final String PRELOAD_FX = "preloadFX";
    public static final String PRELOAD_AUDIO = "preloadAudio";
    public static final String PLAY = "play";
    public static final String STOP = "stop";
    public static final String LOOP = "loop";
    public static final String UNLOAD = "unload";
    private static final String FADE_IN = "fadeIn";
    private static final String FADE_IN_LOOP = "fadeInLoop";
    private static final String FADE_OUT = "fadeOut";

    public static final int DEFAULT_POLYPHONY_VOICES = 15;

    private static final String LOGTAG = "LowLatencyAudio";
    private static final PluginResult RESULT_OK = new PluginResult(Status.OK);

    private static SoundPool soundPool;
    private static HashMap<String, LowLatencyAudioAsset> assetMap;
    private static HashMap<String, FXConfig> soundMap;
    private static HashMap<String, ArrayList<Integer>> streamMap;
    private static List<LowLatencyAudioAsset> pausedAudio;

    private class FXConfig {

        int id;
        float volume = 1;

        public FXConfig(int id) {
            this.id = id;
        }
    }

    @Override
    public void onPause(boolean multitasking) {
        for(LowLatencyAudioAsset asset : assetMap.values()) {
            try {
                if(asset.isPlaying()) {
                    pausedAudio.add(asset);
                    asset.stop();
                }
            } catch (IOException e) {
                // just keep swimming
            }
        }
    }

    /**
     * Called when the activity will start interacting with the user.
     *
     * @param multitasking		Flag indicating if multitasking is turned on for app
     */

    @Override
    public void onResume(boolean multitasking) {
        for(LowLatencyAudioAsset asset : pausedAudio) {
            try {
                asset.loop();
            } catch (IOException e) {
                // just keep swimming
            }
        }
    }

    private PluginResult setVolume(JSONArray data) throws JSONException, IOException {

        String audioID = data.getString(0);
        float volume = (float) data.getDouble(1);
        //Log.d( LOGTAG, "play - " + audioID );

        if (assetMap.containsKey(audioID)) {
            assetMap.get(audioID).setMaxVolume(volume);
        } else if (soundMap.containsKey(audioID)) {
            soundMap.get(audioID).volume = volume;
        } else {
            return RESULT_NO_AUDIOID;
        }

        return RESULT_OK;
    }

    private PluginResult preloadFX(final JSONArray data) throws JSONException, IOException {

        String audioID = data.getString(0);
        if (!soundMap.containsKey(audioID)) {
            String assetPath = data.getString(1);
            String fullPath = "www/".concat(assetPath);

            Log.d(LOGTAG, "preloadFX - " + audioID + ": " + assetPath);

            Context ctx = cordova.getActivity().getApplicationContext();
            AssetManager am = ctx.getResources().getAssets();
            AssetFileDescriptor afd = am.openFd(fullPath);
            int assetIntID = soundPool.load(afd, 1);
            soundMap.put(audioID, new FXConfig(assetIntID));
        } else {
            return RESULT_AUDIOID_EXISTS;
        }

        return RESULT_OK;
    }

    private PluginResult preloadAudio(JSONArray data) throws JSONException, IOException {
        String audioID = data.getString(0);
        if (!assetMap.containsKey(audioID)) {
            String assetPath = data.getString(1);
            Log.d(LOGTAG, "preloadAudio - " + audioID + ": " + assetPath);

            int voices;
            if (data.length() < 2) {
                voices = 0;
            } else {
                voices = data.getInt(2);
            }

            String fullPath = "www/".concat(assetPath);

            Context ctx = cordova.getActivity().getApplicationContext();
            AssetManager am = ctx.getResources().getAssets();
            AssetFileDescriptor afd = am.openFd(fullPath);

            LowLatencyAudioAsset asset = new LowLatencyAudioAsset(afd, voices);
            assetMap.put(audioID, asset);

            return RESULT_OK;
        } else {
            return RESULT_AUDIOID_EXISTS;
        }

    }

    private PluginResult fadeIn(JSONArray data, boolean loop) throws JSONException, IOException {
        String audioID = data.getString(0);
        float duration = (float) data.optDouble(1, 1f);
        if (assetMap.containsKey(audioID)) {
            LowLatencyAudioAsset asset = assetMap.get(audioID);
            asset.fadeIn(duration, loop);
        } else if (soundMap.containsKey(audioID)) {
            return play(data, loop);
        } else {
            return RESULT_NO_AUDIOID;
        }

        return RESULT_OK;
    }

    private PluginResult play(JSONArray data, boolean loop) throws JSONException, IOException {
        String audioID = data.getString(0);
        //Log.d( LOGTAG, "play - " + audioID );

        if (assetMap.containsKey(audioID)) {
            LowLatencyAudioAsset config = assetMap.get(audioID);
            if (loop) {
                config.loop();
            } else {
                config.play();
            }
        } else if (soundMap.containsKey(audioID)) {
            int loops = loop ? -1 : 0;

            ArrayList<Integer> streams = streamMap.get(audioID);
            if (streams == null)
                streams = new ArrayList<Integer>();

            FXConfig config = soundMap.get(audioID);
            int streamID = soundPool
                    .play(config.id, config.volume, config.volume, 1, loops, 1);
            streams.add(streamID);
            streamMap.put(audioID, streams);
        } else {
            return RESULT_NO_AUDIOID;
        }

        return RESULT_OK;
    }

    private PluginResult stop(JSONArray data) throws JSONException, IOException {
        String audioID = data.getString(0);
        //Log.d( LOGTAG, "stop - " + audioID );

        if (assetMap.containsKey(audioID)) {
            assetMap.get(audioID).stop();
        } else if (soundMap.containsKey(audioID)) {
            ArrayList<Integer> streams = streamMap.get(audioID);
            if (streams != null) {
                for (Integer stream : streams) soundPool.stop(stream);
            }
            streamMap.remove(audioID);
        } else {
            return RESULT_NO_AUDIOID;
        }

        return RESULT_OK;
    }

    private PluginResult fadeOut(JSONArray data) throws JSONException, IOException {
        String audioID = data.getString(0);
        float duration = (float) data.optDouble(1, 1f);
        //Log.d( LOGTAG, "stop - " + audioID );

        if (assetMap.containsKey(audioID)) {
            assetMap.get(audioID).fadeOut(duration);
        } else if (soundMap.containsKey(audioID)) {
            return stop(data);
        } else {
            return RESULT_NO_AUDIOID;
        }

        return RESULT_OK;
    }

    private PluginResult unload(JSONArray data) throws JSONException, IOException {
        String audioID = data.getString(0);
        Log.d(LOGTAG, "unload - " + audioID);

        stop(data);

        if (assetMap.containsKey(audioID)) {
            assetMap.get(audioID).unload();
            assetMap.remove(audioID);
        } else if (soundMap.containsKey(audioID)) {
            // streams unloaded and stopped above
            soundPool.unload(soundMap.get(audioID).id);
            soundMap.remove(audioID);
        } else {
            return RESULT_NO_AUDIOID;
        }

        return RESULT_OK;
    }

    @Override
    public boolean execute(final String action, final JSONArray data, final CallbackContext callbackContext) {
        Log.d(LOGTAG, "Plugin Called: " + action);

        cordova.getThreadPool().execute(new Runnable() {
            @Override
            public void run() {
                initSoundPool();

                try {
                    if (PRELOAD_FX.equals(action)) {
                        callbackContext.sendPluginResult(preloadFX(data));

                    } else if (PRELOAD_AUDIO.equals(action)) {
                        callbackContext.sendPluginResult(preloadAudio(data));

                    } else if (PLAY.equals(action)) {
                        callbackContext.sendPluginResult(play(data, false));

                    } else if (LOOP.equals(action)) {
                        callbackContext.sendPluginResult(play(data, true));

                    } else if (FADE_IN.equals(action)) {
                        callbackContext.sendPluginResult(fadeIn(data, false));

                    } else if (FADE_IN_LOOP.equals(action)) {
                        callbackContext.sendPluginResult(fadeIn(data, true));

                    } else if (FADE_OUT.equals(action)) {
                        callbackContext.sendPluginResult(fadeOut(data));

                    } else if (STOP.equals(action)) {
                        callbackContext.sendPluginResult(stop(data));

                    } else if (UNLOAD.equals(action)) {
                        callbackContext.sendPluginResult(unload(data));
                    }
                } catch (Exception ex) {
                    callbackContext.sendPluginResult(new PluginResult(Status.ERROR, ex.toString()));
                }

            }
        });
        return true;
    }

    private void initSoundPool() {
        if (soundPool == null) {
            soundPool = new SoundPool(DEFAULT_POLYPHONY_VOICES, AudioManager.STREAM_MUSIC, 1);
        }

        if (soundMap == null) {
            soundMap = new HashMap<String, FXConfig>();
        }

        if (streamMap == null) {
            streamMap = new HashMap<String, ArrayList<Integer>>();
        }

        if (assetMap == null) {
            assetMap = new HashMap<String, LowLatencyAudioAsset>();
        }

        if(pausedAudio == null) {
            pausedAudio = new ArrayList<LowLatencyAudioAsset>();
        }
    }
}
