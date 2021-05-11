from django.shortcuts import render
from rest_framework import generics
from rest_framework import status
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.contrib.auth.models import User, Group
from rest_framework import viewsets
from rest_framework import permissions
from django.db import connections
from scheduler.serializers import UserSerializer, GroupSerializer,\
    ChangePasswordSerializer, UpdateUserSerializer
from requests import get


class UserViewSet(viewsets.ModelViewSet):
    """
    API endpoint that allows users to be viewed or edited.
    """
    queryset = User.objects.all().order_by('-date_joined')
    serializer_class = UserSerializer
    permission_classes = [permissions.IsAuthenticated]


class GroupViewSet(viewsets.ModelViewSet):
    """
    API endpoint that allows groups to be viewed or edited.
    """
    queryset = Group.objects.all()
    serializer_class = GroupSerializer
    permission_classes = [permissions.IsAuthenticated]


class ChangePasswordView(generics.UpdateAPIView):
    """
    An endpoint for changing password.
    """
    serializer_class = ChangePasswordSerializer
    model = User
    permission_classes = (IsAuthenticated,)

    def get_object(self, queryset=None):
        obj = self.request.user
        return obj

    def update(self, request, *args, **kwargs):
        self.object = self.get_object()
        serializer = self.get_serializer(data=request.data)

        if serializer.is_valid():
            # Check old password
            if not self.object.check_password(serializer.data.get("old_password")):
                return Response({"old_password": ["Wrong password."]}, status=status.HTTP_400_BAD_REQUEST)
            # set_password also hashes the password that the user will get
            self.object.set_password(serializer.data.get("new_password"))
            self.object.save()
            response = {
                'status': 'success',
                'code': status.HTTP_200_OK,
                'message': 'Password updated successfully',
                'data': []
            }

            return Response(response)

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class UpdateProfileView(generics.UpdateAPIView):

    queryset = User.objects.all()
    permission_classes = (IsAuthenticated,)
    serializer_class = UpdateUserSerializer


class Cron(viewsets.ViewSet):
    permission_classes = (IsAuthenticated,)
    isRunning = False

    def create(self, request):
        if not Cron.isRunning:
            Cron.isRunning = True
            try:
                self.runtime_db_health()
            except:
                pass
                Cron.isRunning = False
            finally:
                return Response('Done')
        return Response('Running')

    def list(self, request):
        return Response({'Running': Cron.isRunning})

    def runtime_db_health(self):
        with connections['plugin'].cursor() as cursor:
            cursor.callproc('plugin.get_link')
            row = cursor.fetchone()
            while row is not None:
                res = get(row[1], allow_redirects=False)
                if res.status_code != 200:
                    with connections['plugin'].cursor() as tempCursor:
                        tempCursor.execute(
                            'CALL plugin.remove_link(%s::plugin.id_type)', [str(row[0])])
                row = cursor.fetchone()
