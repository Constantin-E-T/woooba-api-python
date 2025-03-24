from pathlib import Path
from decouple import config, Csv
import dj_database_url


BASE_DIR = Path(__file__).resolve().parent.parent

# SECURITY WARNING: keep the secret key used in production secret!
SECRET_KEY = config('SECRET_KEY', default='django-insecure-key-for-dev')

DEBUG = config('DEBUG', default=True, cast=bool)

ALLOWED_HOSTS = config('ALLOWED_HOSTS', default='*', cast=Csv())

# Application definition
INSTALLED_APPS = [
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    
    # REST framework
    'rest_framework',
    'drf_yasg',
    'corsheaders',
    
    # Project apps
    'api',
    'tasks',
    'support',
    
    # Storage apps
    'storages',
    'minio_storage', 
    # Add this line
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'corsheaders.middleware.CorsMiddleware',
    'whitenoise.middleware.WhiteNoiseMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'core.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'core.wsgi.application'

# REST Framework settings
REST_FRAMEWORK = {
    'DEFAULT_RENDERER_CLASSES': [
        'rest_framework.renderers.JSONRenderer',
        'rest_framework.renderers.BrowsableAPIRenderer',  
    ],
    'DEFAULT_AUTHENTICATION_CLASSES': [],  
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.AllowAny', 
    ],
}

# Database
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
    }
}

# Use PostgreSQL for production
DATABASE_URL = config('DATABASE_URL', default=None)
if DATABASE_URL:
    DATABASES['default'] = dj_database_url.config(
        default=DATABASE_URL,
        conn_max_age=600,
        conn_health_checks=True,
    )

# Password validation
AUTH_PASSWORD_VALIDATORS = [
    {
        'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',
    },
]

# Internationalization
LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'UTC'
USE_I18N = True
USE_TZ = True

# Static files (CSS, JavaScript, Images)
STATIC_URL = 'static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'
MEDIA_URL = 'media/'
MEDIA_ROOT = BASE_DIR / 'media'

# Default primary key field type
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# Add CORS configuration
CORS_ALLOW_ALL_ORIGINS = config('CORS_ALLOW_ALL_ORIGINS', default=DEBUG, cast=bool)
CORS_ALLOWED_ORIGINS = config('CORS_ALLOWED_ORIGINS', default='http://localhost:3000,http://127.0.0.1:3000', cast=Csv())

# MinIO Configuration
MINIO_STORAGE_ENDPOINT = config('MINIO_STORAGE_ENDPOINT', default='storages3-api.serverplus.org')
MINIO_STORAGE_ACCESS_KEY = config('MINIO_STORAGE_ACCESS_KEY', default='')
MINIO_STORAGE_SECRET_KEY = config('MINIO_STORAGE_SECRET_KEY', default='')
MINIO_STORAGE_MEDIA_BUCKET_NAME = config('MINIO_STORAGE_MEDIA_BUCKET_NAME', default='')
MINIO_STORAGE_STATIC_BUCKET_NAME = config('MINIO_STORAGE_STATIC_BUCKET_NAME', default='')
MINIO_STORAGE_USE_HTTPS = config('MINIO_STORAGE_USE_HTTPS', default=True, cast=bool)
MINIO_STORAGE_AUTO_CREATE_MEDIA_BUCKET = config('MINIO_STORAGE_AUTO_CREATE_MEDIA_BUCKET', default=True, cast=bool)
MINIO_STORAGE_AUTO_CREATE_STATIC_BUCKET = config('MINIO_STORAGE_AUTO_CREATE_STATIC_BUCKET', default=True, cast=bool)
MINIO_STORAGE_MEDIA_USE_PRESIGNED = config('MINIO_STORAGE_MEDIA_USE_PRESIGNED', default=True, cast=bool)
MINIO_STORAGE_STATIC_USE_PRESIGNED = config('MINIO_STORAGE_STATIC_USE_PRESIGNED', default=True, cast=bool)

# Optional: Separate media and static files in the same bucket with prefixes
MINIO_STORAGE_MEDIA_URL_ENDPONT = config('MINIO_STORAGE_MEDIA_URL_ENDPONT', default=MINIO_STORAGE_ENDPOINT)
MINIO_STORAGE_STATIC_URL_ENDPONT = config('MINIO_STORAGE_STATIC_URL_ENDPONT', default=MINIO_STORAGE_ENDPOINT)

# Configure Django storage backends to use MinIO
STORAGES = {
    # Media file management
    "default": {
        "BACKEND": "minio_storage.storage.MinioMediaStorage",
    },
    # CSS and JS file management
    "staticfiles": {
        "BACKEND": "minio_storage.storage.MinioStaticStorage",
    },
}

# Override local static and media URLs when using MinIO
if 'minio_storage' in INSTALLED_APPS:
    STATIC_URL = f'https://{MINIO_STORAGE_ENDPOINT}/{MINIO_STORAGE_STATIC_BUCKET_NAME}/static/'
    MEDIA_URL = f'https://{MINIO_STORAGE_ENDPOINT}/{MINIO_STORAGE_MEDIA_BUCKET_NAME}/media/'