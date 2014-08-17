    /*
     *
     * Licensed to the Apache Software Foundation (ASF) under one
     * or more contributor license agreements.  See the NOTICE file
     * distributed with this work for additional information
     * regarding copyright ownership.  The ASF licenses this file
     * to you under the Apache License, Version 2.0 (the
     * "License"); you may not use this file except in compliance
     * with the License.  You may obtain a copy of the License at
     *
     *   http://www.apache.org/licenses/LICENSE-2.0
     *
     * Unless required by applicable law or agreed to in writing,
     * software distributed under the License is distributed on an
     * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
     * KIND, either express or implied.  See the License for the
     * specific language governing permissions and limitations
     * under the License.
     *
     */

    var exec = require('cordova/exec'),
        emptyFn = function () {
        },
        filenameRegex = /^(?:.*\/)?(.+)\.[^\.]+$/;

    module.exports = {

        preload: function () {

            if (arguments[0] instanceof Array) {

                arguments[0].forEach(function (cfg) {
                    module.exports.preload(cfg);
                });
            } else if (typeof arguments[0] === 'object') {

                var cfg = arguments[0];
                // look for type argument and default to fx
                if (cfg.type === 'audio') {
                    module.exports.preloadAudio(cfg)
                } else {
                    module.exports.preloadFX(cfg)
                }

            }
        },

        preloadFX: function () {

            if (arguments[0] instanceof Array) {
                arguments[0].forEach(function (cfg) {
                    module.exports.preloadFX(cfg);
                });
            } else if (typeof arguments[0] === 'object') {

                var cfg = arguments[0],
                    args = [
                        // default the id to the name of the fx file
                        cfg.id || cfg.asset.replace(filenameRegex, '$1'),
                        cfg.asset
                    ],
                    successFn = cfg.success || emptyFn,
                    failFn = cfg.fail || emptyFn;

                cordova.exec(successFn, failFn, "LowLatencyAudio", "preloadFX", args);

            } else {
                // load using arguments list
                return module.exports._preloadFX.apply(this, arguments);
            }
        },

        preloadAudio: function () {

            if (arguments[0] instanceof Array) {
                arguments[0].forEach(function (cfg) {
                    module.exports.preloadAudio(cfg);
                });
            } else if (typeof arguments[0] === 'object') {

                var cfg = arguments[0],
                    args = [
                        // default the id to the name of the audio file if it's not passed
                        cfg.id || cfg.asset.replace(filenameRegex, '$1'),
                        cfg.asset,
                        cfg.volume !== undefined ? cfg.volume : 1.0,
                        cfg.voices !== undefined ? cfg.voices : 1
                    ],
                    successFn = cfg.success || emptyFn,
                    failFn = cfg.fail || emptyFn;

                cordova.exec(successFn, failFn, "LowLatencyAudio", "preloadAudio", args);

            } else {
                // load using argumetn list
                return module.exports._preloadAudio.apply(module.export, arguments);
            }
        },

        play: function (id) {
            if (typeof arguments[1] === 'object') {
                var cfg = arguments[1],
                    successFn = cfg.success || emptyFn,
                    failFn = cfg.fail || emptyFn;
                cordova.exec(successFn, failFn, "LowLatencyAudio", "play", [id]);
            } else {
                module.exports._play.apply(module.export, arguments);
            }
        },

        loop: function (id) {
            if (typeof arguments[1] === 'object') {
                var cfg = arguments[1],
                    successFn = cfg.success || emptyFn,
                    failFn = cfg.fail || emptyFn;
                cordova.exec(successFn, failFn, "LowLatencyAudio", "loop", [id]);
            } else {
                module.exports._loop.apply(module.export, arguments);
            }
        },

        fadeIn: function (id, cfg) {

            cfg = cfg || {};
            var successFn = cfg.success || emptyFn,
                failFn = cfg.fail || emptyFn;

            cordova.exec(successFn, failFn, "LowLatencyAudio", "fadeIn", [id, cfg.duration || 1.0]);
        },

        fadeInLoop: function (id, cfg) {

            cfg = cfg || {};
            var successFn = cfg.success || emptyFn,
                failFn = cfg.fail || emptyFn;
            cordova.exec(successFn, failFn, "LowLatencyAudio", "fadeInLoop", [id, cfg.duration || 1.0]);
        },

        fadeOut: function (id, cfg) {

            cfg = cfg || {};
            var successFn = cfg.success || emptyFn,
                failFn = cfg.fail || emptyFn;

            cordova.exec(successFn, failFn, "LowLatencyAudio", "fadeOut", [id, cfg.duration || 1.0]);
        },

        stop: function (id, cfg) {

            if (typeof arguments[1] === 'object') {
                var successFn = cfg.success || emptyFn,
                    failFn = cfg.fail || emptyFn;
                cordova.exec(successFn, failFn, "LowLatencyAudio", "stop", [id]);
            } else {
                module.exports._stop.apply(module.export, arguments);
            }
        },

        unload: function (ids, cfg) {

            cfg = cfg || {};
            var successFn = cfg.success || emptyFn,
                failFn = cfg.fail || emptyFn;
            
            [].concat(ids).forEach(function (id) {
                cordova.exec(successFn, failFn, "LowLatencyAudio", "unload", [id]);
            });
        },

	    setVolume: function(ids, volume, cfg) {
			cfg = cfg || {};
	        var successFn = cfg.success || emptyFn,
	            failFn = cfg.fail || emptyFn;
		    [].concat(ids).forEach(function (id) {
				cordova.exec(successFn, failFn, "LowLatencyAudio", "setVolume", [id, volume]);
			});
	    },

        // backward compatible versions of functions
        _stop: function (id, success, fail) {
            return cordova.exec(success, fail, "LowLatencyAudio", "stop", [id]);
        },

        _loop: function (id, success, fail) {
            return cordova.exec(success, fail, "LowLatencyAudio", "loop", [id]);
        },

        _play: function (id, success, fail) {
            return cordova.exec(success, fail, "LowLatencyAudio", "play", [id]);
        },

        _preloadFX: function (id, assetPath, success, fail) {
            return cordova.exec(success, fail, "LowLatencyAudio", "preloadFX", [id, assetPath]);
        },

        _preloadAudio: function (id, assetPath, volume, voices, success, fail) {
            if (voices === undefined) voices = 1;
            if (volume === undefined) volume = 1.0;

            return cordova.exec(success, fail, "LowLatencyAudio", "preloadAudio", [
                id,
                assetPath,
                volume,
                voices,
                success,
                fail
            ]);
        }
    };