document.addEventListener('DOMContentLoaded', () => {
    // --- DOM Element Selection ---
    const textInput = document.getElementById('text-to-synthesize');
    const generateBtn = document.querySelector('.generate-btn');
    const outputAudioPlaceholder = document.querySelector('.output-audio-placeholder');
    
    // Reference Audio Elements
    const referenceAudioCard = document.getElementById('reference-audio-card');
    const uploadBtn = referenceAudioCard.querySelector('.upload-btn');
    const closeReferenceAudioBtn = referenceAudioCard.querySelector('.close-btn');
    const waveformContainer = document.getElementById('waveform');
    const waveformText = waveformContainer.querySelector('span');

    // Reference Audio Controls & Display
    const playPauseBtn = document.getElementById('ref-audio-play-pause');
    const timeDisplay = document.getElementById('ref-audio-time');

    // Sliders
    const exaggerationSlider = document.getElementById('exaggeration-slider');
    const temperatureSlider = document.getElementById('temperature-slider');
    const cfgSlider = document.getElementById('cfg-slider');

    let referenceAudioFile = null;
    let wavesurfer = null;

    // --- Helper Functions ---
    // Converts a Base64 Data URL to a File object
    const dataURLtoFile = (dataurl, filename) => {
        const arr = dataurl.split(',');
        const mime = arr[0].match(/:(.*?);/)[1];
        const bstr = atob(arr[1]);
        let n = bstr.length;
        const u8arr = new Uint8Array(n);
        while (n--) {
            u8arr[n] = bstr.charCodeAt(n);
        }
        return new File([u8arr], filename, { type: mime });
    };

    // --- WaveSurfer & Audio State Management ---
    const initializeWaveSurfer = () => {
        if (wavesurfer) wavesurfer.destroy();
        wavesurfer = WaveSurfer.create({
            container: waveformContainer,
            waveColor: '#a1a1aa',
            progressColor: '#6a5af9',
            height: 80,
            barWidth: 2,
            responsive: true,
        });

        wavesurfer.on('play', () => playPauseBtn.textContent = '⏸');
        wavesurfer.on('pause', () => playPauseBtn.textContent = '▶');
        wavesurfer.on('audioprocess', () => {
            timeDisplay.textContent = new Date(wavesurfer.getCurrentTime() * 1000).toISOString().substr(14, 5);
        });
    };

    // Loads audio into the player and stores it in the session
    const loadAndStoreReferenceAudio = (file) => {
        referenceAudioFile = file;
        const reader = new FileReader();
        reader.onload = (e) => {
            sessionStorage.setItem('referenceAudioData', e.target.result);
            sessionStorage.setItem('referenceAudioName', file.name);
            initializeWaveSurfer();
            wavesurfer.load(e.target.result);
            waveformText.textContent = ''; // Clear placeholder text
        };
        reader.readAsDataURL(file);
    };

    // Clears the reference audio from the player and session
    const clearReferenceAudio = () => {
        referenceAudioFile = null;
        sessionStorage.removeItem('referenceAudioData');
        sessionStorage.removeItem('referenceAudioName');
        if (wavesurfer) wavesurfer.empty();
        timeDisplay.textContent = '0:00';
        playPauseBtn.textContent = '▶';
        waveformText.textContent = 'Upload or record audio to see waveform';
        console.log('Reference audio cleared.');
    };

    // Check session storage on page load
    const loadFromSession = () => {
        const audioData = sessionStorage.getItem('referenceAudioData');
        const audioName = sessionStorage.getItem('referenceAudioName');
        if (audioData && audioName) {
            referenceAudioFile = dataURLtoFile(audioData, audioName);
            initializeWaveSurfer();
            wavesurfer.load(audioData);
            waveformText.textContent = '';
            console.log(`Loaded reference audio "${audioName}" from session.`);
        } else {
            initializeWaveSurfer(); // Init empty player
        }
    };

    // --- Event Listeners ---
    const fileInput = document.createElement('input');
    fileInput.type = 'file';
    fileInput.accept = 'audio/wav, audio/mpeg';
    fileInput.style.display = 'none';
    document.body.appendChild(fileInput);

    uploadBtn.addEventListener('click', () => fileInput.click());
    fileInput.addEventListener('change', (e) => e.target.files[0] && loadAndStoreReferenceAudio(e.target.files[0]));
    closeReferenceAudioBtn.addEventListener('click', clearReferenceAudio);

    // Playback controls
    playPauseBtn.addEventListener('click', () => wavesurfer && wavesurfer.playPause());
    document.getElementById('ref-audio-backward').addEventListener('click', () => wavesurfer && wavesurfer.skipBackward(5));
    document.getElementById('ref-audio-forward').addEventListener('click', () => wavesurfer && wavesurfer.skipForward(5));
    document.getElementById('ref-audio-reset').addEventListener('click', () => wavesurfer && wavesurfer.seekTo(0));

    // --- Main Generate Button Logic ---
    generateBtn.addEventListener('click', async () => {
        const textToSynthesize = textInput.value.trim();
        if (!textToSynthesize) {
            alert('Please enter some text to synthesize.');
            return;
        }

        const formData = new FormData();
        formData.append('text', textToSynthesize);
        formData.append('exaggeration', parseFloat(exaggerationSlider.value));
        formData.append('temperature', parseFloat(temperatureSlider.value));
        formData.append('cfg_weight', parseFloat(cfgSlider.value));

        if (referenceAudioFile) {
            formData.append('audio_prompt', referenceAudioFile);
        }

        generateBtn.disabled = true;
        generateBtn.textContent = 'Generating...';
        outputAudioPlaceholder.innerHTML = '<p>Generating audio...</p>';

        try {
            const response = await fetch('/generate_audio', { method: 'POST', body: formData });
            const data = await response.json();
            if (!response.ok) throw new Error(data.error || `Server error ${response.status}`);
            
            if (data.audio_file_path) {
                const audioSrc = `${data.audio_file_path}?t=${new Date().getTime()}`;
                outputAudioPlaceholder.innerHTML = `<audio controls autoplay><source src="${audioSrc}" type="audio/wav"></audio>`;
            } else {
                throw new Error('Server did not return an audio file path.');
            }
        } catch (error) {
            outputAudioPlaceholder.innerHTML = `<p style="color: red;">Error: ${error.message}</p>`;
        } finally {
            generateBtn.disabled = false;
            generateBtn.textContent = 'Generate';
        }
    });

    // --- Slider Setup ---
    document.querySelectorAll('.slider-container').forEach(container => {
        const slider = container.querySelector('input[type="range"]');
        const valueDisplay = container.querySelector('.slider-value');
        const resetButton = container.querySelector('.reset-slider');
        const defaultValue = slider.value;
        const precision = (slider.step.split('.')[1] || []).length;

        const updateValue = () => valueDisplay.textContent = parseFloat(slider.value).toFixed(precision);
        slider.addEventListener('input', updateValue);
        resetButton.addEventListener('click', () => {
            slider.value = defaultValue;
            updateValue();
        });
        updateValue();
    });
    
    // --- Initial Load ---
    loadFromSession();
});