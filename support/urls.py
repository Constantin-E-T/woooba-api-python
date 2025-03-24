from django.urls import path, include
from rest_framework_nested import routers
from .views import ConversationViewSet, MessageViewSet, AttachmentViewSet

# Main router for conversations
router = routers.DefaultRouter()
router.register(r'conversations', ConversationViewSet, basename='conversation')

# Nested router for messages within conversations
conversation_router = routers.NestedDefaultRouter(router, r'conversations', lookup='conversation')
conversation_router.register(r'messages', MessageViewSet, basename='message')

# Nested router for attachments within messages
message_router = routers.NestedDefaultRouter(conversation_router, r'messages', lookup='message')
message_router.register(r'attachments', AttachmentViewSet, basename='attachment')

urlpatterns = [
    path('v1/', include(router.urls)),
    path('v1/', include(conversation_router.urls)),
    path('v1/', include(message_router.urls)),
]