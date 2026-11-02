from django.conf import settings
from django.db import models

# Create your models here.

class Link(models.Model):
    short_code = models.CharField(max_length=10, unique=True)
    original_url = models.URLField(max_length=2048)
    click_count = models.PositiveIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)
    owner = models.ForeignKey(settings.AUTH_USER_MODEL, null=True, blank=True,
                              on_delete=models.SET_NULL, related_name="links")

    def __str__(self):
        return self.short_code