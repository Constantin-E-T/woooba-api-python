from rest_framework import serializers
from .models import Conversation, Message, Attachment

class AttachmentSerializer(serializers.ModelSerializer):
    class Meta:
        model = Attachment
        fields = ['id', 'file', 'filename', 'file_size', 'content_type', 'uploaded_at']
        read_only_fields = ['id', 'filename', 'file_size', 'content_type', 'uploaded_at']

class MessageSerializer(serializers.ModelSerializer):
    attachments = AttachmentSerializer(many=True, read_only=True)
    
    class Meta:
        model = Message
        fields = ['id', 'content', 'created_at', 'is_from_staff', 'sender_name', 'attachments']
        read_only_fields = ['id', 'created_at', 'is_from_staff']

class ConversationSerializer(serializers.ModelSerializer):
    messages = MessageSerializer(many=True, read_only=True)
    
    class Meta:
        model = Conversation
        fields = [
            'id', 'title', 'created_at', 'updated_at', 
            'contact_email', 'contact_name', 'session_key', 'messages'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']