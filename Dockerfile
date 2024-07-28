# Use an official Python runtime as the base image
FROM python:3.11

# Install Flutter dependencies
RUN apt-get update && apt-get install -y curl git unzip xz-utils zip libglu1-mesa

# Install Flutter
RUN git clone https://github.com/flutter/flutter.git /usr/local/flutter
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"
RUN flutter channel stable
RUN flutter upgrade
RUN flutter config --no-analytics
RUN flutter doctor

# Set the working directory in the container
WORKDIR /app

# Copy the backend requirements file into the container
COPY backend/requirements.txt .

# Install the required packages for backend
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application code into the container
COPY . .

# Install frontend dependencies
WORKDIR /app/frontend
RUN flutter pub get

# Build the Flutter web app
RUN flutter build web

# Go back to the main app directory
WORKDIR /app

# Expose the port that the app will run on
EXPOSE 8000

# Set environment variables
ENV PYTHONUNBUFFERED=1

# Create a startup script
RUN echo '#!/bin/sh\n\
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload &\n\
cd /app/frontend && flutter run -d web-server --web-port 5000\n\
wait' > /app/start.sh

RUN chmod +x /app/start.sh

# Run the startup script
CMD ["/app/start.sh"]