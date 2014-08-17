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

import android.content.res.AssetFileDescriptor;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Timer;
import java.util.TimerTask;
import com.blakgeek.cordova.plugin.PolyphonicVoice;

public class LowLatencyAudioAsset {

    private static final String LOGTAG = "LowLatencyAudio";
    private ArrayList<PolyphonicVoice> voices;
    private int playIndex = 0;
    private float maxVolume = 1;

    public LowLatencyAudioAsset(AssetFileDescriptor afd, int numVoices, float maxVolume) throws IOException {
        voices = new ArrayList<PolyphonicVoice>();
        this.maxVolume = maxVolume;

        if (numVoices < 0)
            numVoices = 0;

        for (int x = 0; x < numVoices; x++) {
            PolyphonicVoice voice = new PolyphonicVoice(afd);
            voices.add(voice);
        }
    }

    public LowLatencyAudioAsset(AssetFileDescriptor afd, int numVoices) throws IOException {
        voices = new ArrayList<PolyphonicVoice>();

        if (numVoices < 0)
            numVoices = 0;

        for (int x = 0; x < numVoices; x++) {
           PolyphonicVoice voice = new PolyphonicVoice(afd);
            voices.add(voice);
        }
    }

    public boolean isPlaying() {
        boolean result = false;
        for(PolyphonicVoice voice : voices) {
            result = result | voice.isPlaying();
        }

        return result;
    }

    public PolyphonicVoice play() throws IOException {
        PolyphonicVoice voice = voices.get(playIndex);
        voice.play();
        playIndex++;
        playIndex = playIndex % voices.size();

        return voice;
    }

    public void stop() throws IOException {
        for (PolyphonicVoice voice : voices) {
            voice.stop();
        }
    }

    public void fadeIn(float duration, boolean loop) throws IOException {
        final PolyphonicVoice voice = loop ? loop() : play();
        if (duration > 0) {

            final Timer timer = new Timer(true);
            TimerTask timerTask = new TimerTask() {
                private int ctr = 100;
                @Override
                public void run() {

                    float volume = (float) (1 - Math.log(ctr) / Math.log(100));
                    voice.setVolume(volume * maxVolume);
                    ctr--;
                    if (volume >= 1) {
                        timer.cancel();
                        timer.purge();
                    }
                }
            };

            // calculate delay, cannot be zero, set to 1 if zero
            long delay = (long) (duration / 100);
            if (delay <= 0) delay = 1;
            timer.schedule(timerTask, delay, delay);
        }
    }

    public void fadeOut(float duration) throws IOException {

        if (duration > 0) {
            final Timer timer = new Timer(true);
            TimerTask timerTask = new TimerTask() {
                private int ctr = 0;
                @Override
                public void run() {

                    float volume = (float) (1 - Math.log(ctr) / Math.log(100));
                    setVolume(volume);
                    ctr++;
                    if (volume <= 0) {
                        timer.cancel();
                        timer.purge();
                        try {
                            stop();
                        } catch (IOException ignored) {

                        }
                    }
                }
            };

            // calculate delay, cannot be zero, set to 1 if zero
            long delay = (long) (duration / 100);
            if (delay <= 0) delay = 1;

            timer.schedule(timerTask, delay, delay);
        }
    }

    public PolyphonicVoice loop() throws IOException {
        PolyphonicVoice voice = voices.get(playIndex);
        voice.loop();
        playIndex++;
        playIndex = playIndex % voices.size();

        return voice;
    }

    public void unload() throws IOException {
        this.stop();
        for (PolyphonicVoice voice : voices) {
            voice.unload();
        }
        voices.removeAll(voices);
    }

    public void setMaxVolume(float maxVolume) {
        this.maxVolume = maxVolume;
        for(PolyphonicVoice voice : voices) {
            if(voice.getVolume() > this.maxVolume) {
                voice.setVolume(this.maxVolume);
            }
        }
    }

    public void setVolume(float volume) {
        for(PolyphonicVoice voice : voices) {
            voice.setVolume(this.maxVolume * volume);
        }
    }
}
