document.addEventListener('DOMContentLoaded', () => {
    const textInput = document.getElementById('textInput');
    const convertBtn = document.getElementById('convertBtn');
    const audioPlayer = document.getElementById('audioPlayer');

    convertBtn.addEventListener('click', async () => {
        const text = textInput.value.trim();
        
        if (!text) {
            alert('Please enter some text to convert to speech.');
            return;
        }

        try {
            convertBtn.disabled = true;
            convertBtn.textContent = 'Converting...';

            const response = await fetch('/convert', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ text }),
            });

            if (!response.ok) {
                throw new Error('Failed to convert text to speech');
            }

            const blob = await response.blob();
            const audioUrl = URL.createObjectURL(blob);
            
            audioPlayer.src = audioUrl;
            audioPlayer.style.display = 'block';
            audioPlayer.play();
        } catch (error) {
            console.error('Error:', error);
            alert('Failed to convert text to speech. Please try again.');
        } finally {
            convertBtn.disabled = false;
            convertBtn.textContent = 'Convert to Speech';
        }
    });
}); 