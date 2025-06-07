# Chatterbox TTS Demo

A Firebase Studio template for generating high-quality speech from text with reference audio styling using the Chatterbox TTS model.

<a href="https://studio.firebase.google.com/new?template=https%3A%2F%2Fgithub.com%2Frajgundluru%2Fchatterbox-template">
  <picture>
    <source
      media="(prefers-color-scheme: dark)"
      srcset="https://cdn.firebasestudio.dev/btn/open_dark_32.svg">
    <source
      media="(prefers-color-scheme: light)"
      srcset="https://cdn.firebasestudio.dev/btn/open_light_32.svg">
    <img
      height="32"
      alt="Open in Firebase Studio"
      src="https://cdn.firebasestudio.dev/btn/open_blue_32.svg">
  </picture>
</a>

## Getting Started

This template provides a basic setup for a web application that leverages the Chatterbox TTS model for text-to-speech generation with reference audio styling.

### In Firebase Studio

Once you open this template in Firebase Studio:


### Project Structure

-   `main.py`: The Python Flask backend that handles text-to-speech generation using the Chatterbox TTS model and serves the static frontend files.
-   `src/index.html`: The main HTML file for the web interface.
-   `src/style.css`: The CSS file for styling the web interface.
-   `src/script.js`: The JavaScript file for frontend interactivity, including sending text to the backend and playing generated audio.

## Features

-   Generate high-quality speech from text.
-   Optionally apply styling from a reference audio file.
-   Adjust exaggeration and CFG/Pace parameters.
-   Record or upload reference audio directly in the browser.

