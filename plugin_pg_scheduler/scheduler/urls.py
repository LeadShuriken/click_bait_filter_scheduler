from django.urls import path, include
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated

from scheduler import views
from patches import router


class DocsView(APIView):
    """
    RESTFul Documentation
    """
    permission_classes = (IsAuthenticated,)

    def get(self, request, *args, **kwargs):
        apidocs = {
            'cron': request.build_absolute_uri('cron/'),
            'rate': request.build_absolute_uri('rate/'),
            'django/users': request.build_absolute_uri('django/users/'),
            'django/changepassword': request.build_absolute_uri('django/changepassword/'),
            'django/updateprofile': request.build_absolute_uri('django/updateprofile/'),
            'django/groups': request.build_absolute_uri('django/groups/')}
        return Response(apidocs)


router = router.DefaultRouter()
router.register(r'django/users', views.UserViewSet)
router.register(r'django/groups', views.GroupViewSet)
router.register(r'cron', views.Cron, basename='Cron')
router.register(r'rate', views.Rate, basename='Rate')
# router.extend(db_router)

urlpatterns = [
    path('', DocsView.as_view()),
    path('django/changepassword',
         views.ChangePasswordView.as_view(), name='auth_change_password'),
    path('django/updateprofile',
         views.UpdateProfileView.as_view(), name='auth_update_profile'),
    path('', include(router.urls)),
    path('api-auth/', include('rest_framework.urls', namespace='rest_framework'))
]
