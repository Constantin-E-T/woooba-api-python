FROM python:3.12-slim

WORKDIR /app

# Install dependencies
RUN pip install --upgrade pip setuptools --root-user-action=ignore

# Copy requirements and install
COPY requirements.txt .
RUN pip install --no-cache-dir --root-user-action=ignore -r requirements.txt

# Copy project
COPY . .

# Set port to 80 for CapRover
ENV PORT=80

# Expose port 80
EXPOSE 80

RUN python manage.py collectstatic --noinput
# Run migrations and start server
CMD python manage.py migrate && gunicorn core.wsgi:application --bind 0.0.0.0:$PORT