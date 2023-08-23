FROM continuumio/miniconda3

# Set the working directory in the container to /app
WORKDIR /app

# Copy the current directory contents into the container at /app
COPY  app.py config.py audio_nl.mp3 audio_en.mp3 environment.yaml /app
RUN mkdir -p /app/uploads

# Basic environment
#RUN pip install torch==2.0.0+cu118 torchvision==0.15.1+cu118 torchaudio==2.0.1 --index-url https://download.pytorch.org/whl/cu118

# Install the required packages
#RUN pip install --no-cache-dir -r requirements.txt
RUN apt update && apt install -y ffmpeg
RUN conda env create -f /app/environment.yaml

# Run once to download the models into the image
ARG hftoken
RUN /bin/bash -c "source activate whisperx && cd /app; whisperx --hf_token $hftoken --model large-v2 --align_model WAV2VEC2_ASR_LARGE_LV60K_960H --diarize --compute_type float32 --lang nl ./audio_nl.mp3"
RUN /bin/bash -c "source activate whisperx && cd /app; whisperx --hf_token $hftoken --model large-v2 --align_model WAV2VEC2_ASR_LARGE_LV60K_960H --diarize --compute_type float32 --lang en ./audio_en.mp3"

# Install flask
RUN /bin/bash -c "source activate whisperx && pip install flask"

# Set environment variable to tell Flask to run in production mode
ENV FLASK_ENV=production

# Make port 5000 available to the world outside this container
EXPOSE 5000

# Define environment variable for Flask to run on 0.0.0.0
ENV FLASK_RUN_HOST=0.0.0.0

# Run the command to start your app
CMD ["/opt/conda/envs/whisperx/bin/flask", "run"]