from django.db import models
import uuid

class Conversation(models.Model):
    """
    Represents a support conversation between a user and support staff.
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    title = models.CharField(max_length=255)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    # Basic user information (for anonymous users)
    contact_email = models.EmailField(blank=True)
    contact_name = models.CharField(max_length=255, blank=True)
    
    # To identify conversations from the same client
    session_key = models.CharField(max_length=255, blank=True)
    
    class Meta:
        ordering = ['-updated_at']
    
    def __str__(self):
        return f"Conversation {self.id}: {self.title}"

class Message(models.Model):
    """
    Represents a message within a conversation.
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    conversation = models.ForeignKey(Conversation, on_delete=models.CASCADE, related_name='messages')
    content = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    
    # Distinguishes between user and staff messages
    is_from_staff = models.BooleanField(default=False)
    sender_name = models.CharField(max_length=255, blank=True)
    
    class Meta:
        ordering = ['created_at']
    
    def __str__(self):
        return f"Message in {self.conversation.id}"

class Attachment(models.Model):
    """
    Represents a file attachment in a conversation.
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    message = models.ForeignKey(Message, on_delete=models.CASCADE, related_name='attachments')
    file = models.FileField(upload_to='support_attachments/%Y/%m/%d/')
    filename = models.CharField(max_length=255)
    file_size = models.PositiveIntegerField()
    content_type = models.CharField(max_length=100)
    uploaded_at = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return f"Attachment {self.filename} for message {self.message.id}"