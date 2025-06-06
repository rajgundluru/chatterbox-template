document.addEventListener('DOMContentLoaded', () => {
    const textInput = document.getElementById('text-input');
    const convertBtn = document.getElementById('generate-btn');
    const audioPlayer = document.getElementById('audio-player'); // Corrected ID

    // Early check for elements and log if not found
    if (!textInput) {
        console.error("CRITICAL: textInput element with ID 'text-input' not found on DOMContentLoaded.");
    }
    if (!convertBtn) {
        console.error("CRITICAL: convertBtn element with ID 'generate-btn' not found on DOMContentLoaded.");
        return; // If button isn't found, no point in proceeding
    }
    if (!audioPlayer) {
        console.error("CRITICAL: audioPlayer element with ID 'audio-player' not found on DOMContentLoaded.");
    }

    convertBtn.addEventListener('click', async () => {
        if (!textInput) {
            alert('Error: The text input field was not found in the document. Cannot get text.');
            console.error("Error in click handler: textInput is null.");
            return;
        }
        const text = textInput.value.trim();
        
        if (!text) {
            alert('Please enter some text to convert to speech.');
            return;
        }

        const originalButtonText = convertBtn.textContent; // Store original button text from HTML/previous state
        convertBtn.disabled = true;
        convertBtn.textContent = 'Converting...';

        try {
            const response = await fetch('/generate_audio', { // Corrected URL
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ text }),
            });

            if (!response.ok) {
                let errorMsg = 'Failed to convert text to speech';
                try {
                    // Try to get more specific error from server response
                    const errorData = await response.json(); 
                    if (errorData && errorData.error) {
                        errorMsg += `: ${errorData.error}`;
                    } else {
                        errorMsg += `: Server error ${response.status} ${response.statusText}`;
                    }
                } catch (e) {
                    // Fallback if response is not JSON or error structure is different
                    errorMsg += `: Server error ${response.status} ${response.statusText}`;
                }
                throw new Error(errorMsg);
            }

            const data = await response.json(); // Parse the JSON response
            const audioFilePath = data.audio_file_path; // Get the file path

            if (!audioFilePath) {
                throw new Error("Server did not return an audio file path.");
            }
            
            if (!audioPlayer) {
                alert('Error: The audio player element was not found. Cannot play audio.');
                console.error("Error in click handler: audioPlayer is null.");
                return;
            }
            audioPlayer.src = audioFilePath; // Set the src to the path from the server
            audioPlayer.style.display = 'block';
            audioPlayer.play();
        } catch (error) {
            console.error('Error during conversion process:', error);
            alert(error.message || 'An unexpected error occurred. Check console for details.');
        } finally {
            convertBtn.disabled = false;
            convertBtn.textContent = originalButtonText; // Restore original button text
        }
    });
});