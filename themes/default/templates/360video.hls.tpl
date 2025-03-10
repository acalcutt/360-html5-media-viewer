{include file="header.tpl"}
{include file="menu.tpl"}
<div class="col content" id="content">
	<div id="container" ondragstart="return false;" ondrop="return false;">
		<video playsinline id="video" class="video_default"></video>
		<canvas id="360canvas" class="canvas_default"></canvas>
		<div id="canvas_message" class="canvas_center"></div>
		<menu id="controls">
			<span class="video-icon all_controls"><b>{$title}</b></span>
			<br />
			<span id="iconShowHideMenu" class="video-icon" title="Toggle Menu"><img src="{$theme_dir}images/close-pane-48.png" id="showhidemenubtn1" class="video-button menu_default_visible"/><img src="{$theme_dir}images/open-pane-48.png" id="showhidemenubtn2" class="video-button menu_default_hidden"/></span>
			<span id="iconShowHide" class="video-icon" title="Toggle Controls"><img class="video-button" id="showhidebtn" src="{$theme_dir}images/control-panel-64.png"></span>
			<span id="all_controls" class="all_controls">
				<span id="iconPlayPause" class="video-icon" title="Play"><img class="video-button" id="playbtn" src="{$theme_dir}images/play-60.png"></span>
				<span id="iconSeekBackward" class="video-icon" data-skip="-10" title="10s Backward"><img class="video-button" src="{$theme_dir}images/rewind-60.png"></span>
				<span id="iconSeekForward" class="video-icon" data-skip="10" title="10s Forward"><img class="video-button" src="{$theme_dir}images/fast-forward-60.png"></span>
				<span id="iconPreviousFile" class="video-icon" title="Previous File"><img class="video-button" src="{$theme_dir}images/node-up-60.png"></span>
				<span id="iconNextFile" class="video-icon" title="Next File"><img class="video-button" src="{$theme_dir}images/node-down-60.png"></span>
				<span id="iconCamView" class="video-icon" title="Source View"><img class="video-button" id="videobtn" src="{$theme_dir}images/video-camera-60.png"></span>
				<span id="iconFullscreen" class="video-icon" title="Full Screen"><img class="video-button" src="{$theme_dir}images/fit-to-width-60.png"></span>
				<span id="iconSoundMute" class="video-icon" title="Full Screen"><img class="video-button" id="soundmutebtn" src="{$theme_dir}images/mute-60.png" title="Mute/Unmute"></span>
				<span class="inline nowrap player-btn video-icon">Volume: <input class="slider" id="volume" max="1" min="0" name="volume" step="0.05" type="range" value="1"></span>
				<span class="inline nowrap player-btn video-icon">Seek: <input class="slider" id="progress-bar" max="100" min="0" oninput="seek(this.value)" step="0.01" type="range" value="0"><label id="current">00:00</label>/<label id="duration">00:00</label></span>
				<span class="inline nowrap player-btn video-icon">Speed: <input class="slider" id='playbackRate' max="2.5" min="0.1" name='playbackRate' step="0.1" type="range" value="1"><label id="pbrate">1.0x</label></span>
				<span class="view_controls">
					<span class="inline nowrap player-btn video-icon">Zoom: <input class="canv_slider" id="zoom_range" type="range" max="3" min=".4" step=".1" value="{$zoom}"><label id="zoom_range_label">{$zoom}x</label></span>
					<span class="inline nowrap player-btn video-icon">Up/Down: <input class="canv_slider" id="default_z_view" type="range" max="90" min="-90" step="1" value="{$default_z}"><label id="default_z_view_label">{$default_z}°</label></span>
					<span class="inline nowrap player-btn video-icon">Left/Right: <input class="canv_slider" id="default_y_view" type="range" max="180" min="-180" step="1" value="{$default_y}"><label id="default_y_view_label">{$default_y}°</label></span>
					<span class="inline nowrap player-btn video-icon">Rotate: <input class="canv_slider" id="default_x_view" type="range" max="360" min="0" step="1" value="{$default_x}"><label id="default_x_view_label">{$default_x}°</label></span>
				</span>
			</span>
		</menu>
	</div>
	<script>
		window.isEquirectangular = {if $isEquirectangular eq 1}true{else}false{/if};
	</script>
	<script src="lib/360-view-video.js" type="module"></script>
	<script src="lib/hls.min.js"></script>
	<script>
		var video = document.getElementById('video');
		var initialVideoBitrate = {$initialVideoBitrate|default:-1};
		var autoplay = {$autoplay|default:1};
		var startTime = {$startTime|default:0};

		var hls = null;
		if (Hls.isSupported()) {
			hls = new Hls();
			hls.loadSource('{$file}'); {* Load the HLS manifest *}
			hls.attachMedia(video);

			hls.on(Hls.Events.MANIFEST_PARSED, function() {
				// Find the closest level index
				let bestLevel = -1;
				let bestLevelDiff = Infinity;

				for (let i = 0; i < hls.levels.length; i++) {
					const level = hls.levels[i];
					const bitrate = level.bitrate;
					const diff = Math.abs(bitrate - initialVideoBitrate);
					console.log('level:' + i + ' bitrate:' + bitrate + ' diff:' + diff);
					if (diff < bestLevelDiff && bitrate <= initialVideoBitrate) {
						bestLevelDiff = diff;
						bestLevel = i;
					}
				}

				if(bestLevel != -1) {
					hls.startLevel = bestLevel;
					console.log('bestLevel:' + bestLevel);
				}

				//Check to ensure the currentTime = initialTim
				video.currentTime = startTime;

				video.muted = true;
				if (autoplay == 1) {
					video.play();
				}
			});

			hls.on(Hls.Events.ERROR, function(event, data) {
				console.warn("HLS.js error:", data);
			});
		} else if (video.canPlayType('application/vnd.apple.mpegurl')) {
			video.src = '{$file}';
			video.addEventListener('loadeddata', function() {
				video.muted = true;
				video.currentTime = startTime;
				if (autoplay == 1) {
					video.play();
				}
			});

		} else {
			// Use the MP4 fallback source if HLS is not supported at all
			video.src = '{$video_fallback}';
			video.type = 'video/mp4';
			video.addEventListener('loadeddata', function() {
				video.muted = true;
				video.currentTime = startTime;
				if (autoplay == 1) {
					video.play();
				}
			});
		}

		// Wait for the video to load its metadata before initializing Three.js
		video.addEventListener('loadeddata', function() {
			video.currentTime = startTime;
		});

		var urlParams = new URLSearchParams(window.location.search);
		var url = urlParams.get('file');
		const container = document.getElementById("container");
		const contentElement = document.getElementById('content');
		const canvas_message = document.getElementById('canvas_message');
		const progressBar = document.getElementById('progress-bar');
		const hide_controls = document.getElementById('iconShowHide');
		const toggle = document.getElementById('iconPlayPause');
		const skip_forward = document.getElementById('iconSeekBackward');
		const skip_backward = document.getElementById('iconSeekForward');
		const file_forward = document.getElementById('iconNextFile');
		const file_backward = document.getElementById('iconPreviousFile');
		const full_screen = document.getElementById('iconFullscreen');
		const cam_view = document.getElementById('iconCamView');
		const iconSoundMute = document.getElementById('iconSoundMute');
		const soundmutebtn = document.getElementById('soundmutebtn');
		const volume = document.getElementById('volume');
		const playbackRate = document.getElementById('playbackRate');
		const CurrentFile = '{$file}';
		const FileList = {$file_list|json_encode};

		function togglePlay() {
			const playState = video.paused ? 'play' : 'pause';
			video[playState](); // Call play or paused method
			updateButton();
			updateAutoplayParam(video.paused);
		}

		function updateAutoplayParam(paused) {
			// Set autoplay value based on video state
			//If we are playing set the video state to 0 or 1
			const autoplayValue = (paused) ? 1 : 0;

			//Get the values
			const urlParams = new URLSearchParams(window.location.search);

			//Sets or updates the value
			urlParams.set('paused', autoplayValue);

			const newURL = '{$smarty.const.JS_TICK}' + window.location.pathname + '?{$smarty.const.JS_TICK}' + urlParams.toString();
			history.replaceState(null, '', newURL);
		}

		function updateButton() {
			image = document.getElementById('playbtn');
			if (video.paused) {
				image.src = "{$theme_dir}images/play-60.png";
				toggle.setAttribute('title', 'Play');
			} else {
				image.src = "{$theme_dir}images/pause-60.png";
				toggle.setAttribute('title', 'Pause');
			}
			canvas_message.innerHTML = "";
		}

		function PlayNextFile() {
			var i = FileList.indexOf(CurrentFile);
			i = i + 1; // increase i by one
			i = i % FileList.length; // if we've gone too high, start from `0` again
			var url = "{$website_root}index.php?file=" + FileList[i];
			window.location.href = url;
		}

		function PlayPrevFile() {
			var i = FileList.indexOf(CurrentFile);
			if (i === 0) { // i would become 0
				i = FileList.length; // so put it at the other end of the array
			}
			i = i - 1; // decrease by one
			var url = "{$website_root}index.php?file=" + FileList[i];
			window.location.href = url;
		}

		function skip() {
			video.currentTime += parseFloat(this.dataset.skip);
		}

		function rangeUpdate() {
			video[this.name] = this.value;
			if(this.name == "playbackRate") {
				$("#pbrate").text((Number(this.value).toFixed(1)) + "x");
			}
		}

		function updateProgressBar() {
			// Work out how much of the media has played via the duration and currentTime parameters
			var percentage = Math.floor((100 / video.duration) * video.currentTime);
			// Update the progress bar's value
			progressBar.value = percentage;
			// Update the progress bar's text (for browsers that don't support the progress element)
			progressBar.innerHTML = percentage + '% played';
			// Update Text Labels
			updateProgressTime(this.currentTime, this.duration);
		}

		function updateProgressTime(currentTime, duration){
			$("#current").text(formatTime(currentTime)); //Change #current to currentTime
			$("#duration").text(formatTime(duration));
		}

		function formatTime(seconds) {
			if(isNaN(seconds)) {
				return "00:00";
			} else {
				var date = new Date(null);
				date.setSeconds(seconds);
				var hours = date.toISOString().substr(11, 2);
				if(hours == "00") {
					var result = date.toISOString().substr(14, 5);
				} else {
					var result = date.toISOString().substr(11, 8);
				}
				return result;
			}
		}

		function seek(e) {
			progress_val = e / 100;
			video.currentTime = progress_val * video.duration;
			progressBar.innerHTML = progressBar.value + '% played';
			canvas_message.innerHTML = "";
		}

		function scrub(e) {
			const scrubTime = (e.offsetX / progress.offsetWidth) * video.duration;
			video.currentTime = scrubTime;
		}

		function goFullScreen(){
			if (!document.fullscreenElement) {
				container.requestFullscreen();
			} else {
				document.exitFullscreen();
			}
			onWindowResize();
		}

		function toggleSoundMute() {
			video.muted = !video.muted; // Toggle the muted state

			if (video.muted) {
				soundmutebtn.src = "{$theme_dir}images/mute-60.png"; // Show mute icon
			} else {
				soundmutebtn.src = "{$theme_dir}images/sound-60.png"; // Show unmute icon
			}
		}

 

		function toggleVideo() {
			$('.video_default').toggleClass('active');
			$('.canvas_default').toggleClass('hidden');
			$('.view_controls').toggleClass('hidden');
			var resizeEvent = window.document.createEvent('UIEvents');
			resizeEvent.initUIEvent('resize', true, false, window, 0);
			window.dispatchEvent(resizeEvent);

			var videobtn = document.getElementById('videobtn');
			if (video.classList.contains("active")) {
				videobtn.src = "{$theme_dir}images/panorama-60.png";
				cam_view.setAttribute('title', '360 View');
			} else {
				videobtn.src = "{$theme_dir}images/video-camera-60.png";
				cam_view.setAttribute('title', 'Source View');
			}
		}

		function HideControls() {
			$('.all_controls').toggleClass('hidden');
		}

		function EndPrompt() {
			var i = FileList.indexOf(CurrentFile);
			if (i === 0) { // i would become 0
				i = FileList.length; // so put it at the other end of the array
			}
			i = i - 1; // decrease by one
			var PrevFile = FileList[i];
			var PrevExt = PrevFile.split('.').pop().toLowerCase();
			var PrevPath = PrevFile.substring(0, PrevFile.lastIndexOf("/"));
			var PrevThumb = '{$website_root}' + PrevPath + '/thumbnail.jpg';
			var PrevLinkText = PrevFile.replace('files/', '');

			if ((PrevExt == 'jpg') || (PrevExt == 'png')) {
				var PrevThumb = PrevFile;
			} else {
				var PrevThumb = '{$website_root}' + PrevPath + '/thumbnail.jpg';
			}

			var i = FileList.indexOf(CurrentFile);
			i = i + 1; // increase i by one
			i = i % FileList.length; // if we've gone too high, start from `0` again
			var NextFile = FileList[i];
			var NextExt = NextFile.split('.').pop().toLowerCase();
			var NextPath = NextFile.substring(0, NextFile.lastIndexOf("/"));
			var NextLinkText = NextFile.replace('files/', '');

			if ((NextExt == 'jpg') || (NextExt == 'png')) {
				var NextThumb = NextFile;
			} else {
				var NextThumb = '{$website_root}' + NextPath + '/thumbnail.jpg';
			}

			canvas_message.innerHTML = '<div id="canvasNextFile" title="Next File" class="canv_msg"><div>Next File &rarr;<br />' + NextLinkText + '</div><div><img src="' + NextThumb + '" class="canv_thumb"></div></div><br /><div id="canvasPrevFile" title="Previous File" class="canv_msg"><div>&larr; Previous File<br />' + PrevLinkText + '</div><div><img src="' + PrevThumb + '" class="canv_thumb"></div></div>';
			var canv_file_forward = document.getElementById('canvasNextFile');
			var canvfile_backward = document.getElementById('canvasPrevFile');
			canv_file_forward.addEventListener('click', PlayNextFile);
			canvfile_backward.addEventListener('click', PlayPrevFile);
		}

		contentElement.addEventListener('transitionend', function(event) {
			if (event.propertyName === 'left') {
				onWindowResize();
			}
		});

		// Event listeners
		video.addEventListener('click', togglePlay);
		video.addEventListener('play', updateButton);
		video.addEventListener('pause', updateButton);
		video.addEventListener('timeupdate', updateProgressBar, false);
		video.addEventListener("loadeddata", updateProgressBar, false);
		video.addEventListener('ended',EndPrompt,false);

		toggle.addEventListener('click', togglePlay);
		hide_controls.addEventListener('click', HideControls);
		skip_forward.addEventListener('click', skip);
		skip_backward.addEventListener('click', skip);
		file_forward.addEventListener('click', PlayNextFile);
		file_backward.addEventListener('click', PlayPrevFile);
		full_screen.addEventListener('click', goFullScreen);
		cam_view.addEventListener('click', toggleVideo);
		iconSoundMute.addEventListener('click', toggleSoundMute);
		volume.addEventListener('change', rangeUpdate);
		volume.addEventListener('mousemove', rangeUpdate);
		playbackRate.addEventListener('change', rangeUpdate);
		playbackRate.addEventListener('mousemove', rangeUpdate);

		contentElement.addEventListener('transitionend', function(event) {
			if (event.propertyName === 'left') {
				onWindowResize();
			}
		});

		let mousedown = false;
	</script>
</div>
{include file="footer.tpl"}
