from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from django.shortcuts import get_object_or_404

from .models import Conversation, Message, Attachment
from .serializers import ConversationSerializer, MessageSerializer, AttachmentSerializer

class ConversationViewSet(viewsets.ModelViewSet):
    """
    API endpoint for support conversations
    """
    serializer_class = ConversationSerializer
    parser_classes = [JSONParser, MultiPartParser, FormParser]
    
    def get_queryset(self):
        """
        Filter conversations by session_key if provided
        """
        queryset = Conversation.objects.all()
        session_key = self.request.query_params.get('session_key', None)
        
        if session_key:
            queryset = queryset.filter(session_key=session_key)
            
        return queryset
    
    @action(detail=True, methods=['post'])
    def add_message(self, request, pk=None):
        """
        Add a message to an existing conversation
        """
        conversation = self.get_object()
        
        # Create message
        serializer = MessageSerializer(data=request.data)
        if serializer.is_valid():
            # Set is_from_staff based on request data or default to user message
            is_staff = request.data.get('is_from_staff', False)
            
            message = serializer.save(
                conversation=conversation,
                is_from_staff=is_staff,
                sender_name=request.data.get('sender_name', '')
            )
            
            # Update conversation timestamp (touches updated_at)
            conversation.save()
            
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class MessageViewSet(viewsets.ModelViewSet):
    """
    API endpoint for messages within a conversation
    """
    serializer_class = MessageSerializer
    
    def get_queryset(self):
        conversation_id = self.kwargs.get('conversation_pk')
        return Message.objects.filter(conversation__id=conversation_id)
    
    def perform_create(self, serializer):
        conversation_id = self.kwargs.get('conversation_pk')
        conversation = get_object_or_404(Conversation, id=conversation_id)
        serializer.save(conversation=conversation)

class AttachmentViewSet(viewsets.ModelViewSet):
    """
    API endpoint for file attachments
    """
    serializer_class = AttachmentSerializer
    parser_classes = [MultiPartParser, FormParser]
    
    def get_queryset(self):
        message_id = self.kwargs.get('message_pk')
        return Attachment.objects.filter(message__id=message_id)
    
    def perform_create(self, serializer):
        message_id = self.kwargs.get('message_pk')
        message = get_object_or_404(Message, id=message_id)
        
        # Get file from request
        file_obj = self.request.FILES.get('file')
        if not file_obj:
            return Response(
                {'error': 'No file provided'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Save attachment with file metadata
        serializer.save(
            message=message,
            file=file_obj,
            filename=file_obj.name,
            file_size=file_obj.size,
            content_type=file_obj.content_type or 'application/octet-stream'
        )