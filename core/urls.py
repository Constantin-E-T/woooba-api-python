from decouple import config, Csv
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from api.views import IndexView
from rest_framework import permissions
from drf_yasg.views import get_schema_view
from drf_yasg import openapi

schema_view = get_schema_view(
   openapi.Info(
      title="WOOOBA API Python Django REST Framework", 
      default_version='v1.0.0',
      description="WOOOBA REST API",
      terms_of_service="https://www.woooba.com/terms/",
      contact=openapi.Contact(email="conn@ewoooba.io"),
      license=openapi.License(name="BSD License"),
   ),
   public=True,
   permission_classes=(permissions.AllowAny,),
   authentication_classes=[],
   validators=[],
)

urlpatterns = [
    path('', IndexView.as_view(), name='index'),
    path('api/', include('api.urls')),
    path('tasks/', include('tasks.urls')),
    
    # Swagger UI URLs
    path('swagger/', schema_view.with_ui('swagger', cache_timeout=0), name='schema-swagger-ui'),
    path('redoc/', schema_view.with_ui('redoc', cache_timeout=0), name='schema-redoc'),
]

# static/media URL patterns when not using MinIO in development
if settings.DEBUG and 'minio_storage' not in settings.INSTALLED_APPS:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)