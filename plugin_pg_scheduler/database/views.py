from django.shortcuts import render
from django.db import connections
from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response


class DatabaseUsers(viewsets.ViewSet):
    permission_classes = (IsAuthenticated,)

    def list(self, request):
        with connections['primary'].cursor() as cursor:
            cursor.callproc('plugin.get_all_users')
            row = cursor.fetchone()

        return Response(row)
