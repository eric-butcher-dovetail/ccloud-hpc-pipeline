# Carolina Cloud Data Science Pipeline
# Base image from Carolina Cloud's optimized data science stack
FROM carolinacloud/data-science:latest

# Metadata
LABEL maintainer="devops@example.com"
LABEL description="High-performance data analysis pipeline for Carolina Cloud"
LABEL version="1.0"

# Set working directory
WORKDIR /app

# Install additional Python dependencies
# Using specific versions for reproducibility
RUN pip install --no-cache-dir \
    pandas==2.1.4 \
    numpy==1.26.2 \
    scipy==1.11.4 \
    matplotlib==3.8.2 \
    seaborn==0.13.0

# Copy analysis script
COPY analysis.py /app/analysis.py

# Create output directory
RUN mkdir -p /app/output

# Set environment variables for optimal performance
ENV PYTHONUNBUFFERED=1
ENV OMP_NUM_THREADS=4
ENV OPENBLAS_NUM_THREADS=4
ENV MKL_NUM_THREADS=4

# Default command runs the analysis
CMD ["python", "analysis.py"]

