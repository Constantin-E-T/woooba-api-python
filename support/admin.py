from django.contrib import admin
from .models import Conversation, Message, Attachment

class MessageInline(admin.TabularInline):
    model = Message
    extra = 0

class AttachmentInline(admin.TabularInline):
    model = Attachment
    extra = 0

@admin.register(Conversation)
class ConversationAdmin(admin.ModelAdmin):
    list_display = ('id', 'title', 'contact_name', 'contact_email', 'created_at', 'updated_at')
    search_fields = ('title', 'contact_name', 'contact_email')
    list_filter = ('created_at', 'updated_at')
    inlines = [MessageInline]

@admin.register(Message)
class MessageAdmin(admin.ModelAdmin):
    list_display = ('id', 'conversation', 'sender_name', 'is_from_staff', 'created_at')
    list_filter = ('is_from_staff', 'created_at')
    search_fields = ('content', 'sender_name')
    inlines = [AttachmentInline]

@admin.register(Attachment)
class AttachmentAdmin(admin.ModelAdmin):
    list_display = ('id', 'message', 'filename', 'content_type', 'uploaded_at')
    list_filter = ('content_type', 'uploaded_at')
    search_fields = ('filename',)